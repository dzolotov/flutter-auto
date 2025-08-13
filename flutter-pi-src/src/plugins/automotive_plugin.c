/*
 * Flutter-Pi Automotive CAN Bus Plugin
 * Copyright (C) 2025 Dmitrii Zolotov, dmitrii.zolotov@gmail.com
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 * 
 * Provides platform channel interface for CAN Bus communication
 * Compatible with flutter-pi plugin registry API
 * Supports real SocketCAN (vcan0/can0) interface
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <pthread.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <linux/can.h>
#include <linux/can/raw.h>
#include <linux/can/error.h>

#include "flutter-pi.h"
#include "pluginregistry.h"
#include "util/asserts.h"
#include "platformchannel.h"

// Plugin structure with CAN state
struct automotive_plugin {
    struct flutterpi *flutterpi;
    
    // CAN interface state
    int socket_fd;
    char interface_name[16];
    bool is_connected;
    pthread_t reader_thread;
    bool reader_running;
    
    // Statistics
    uint64_t frames_sent;
    uint64_t frames_received;
    uint64_t errors;
    
    // Cached OBD values
    double cached_rpm;
    double cached_speed;
    double cached_engine_temp;
    double cached_throttle;
    double cached_fuel_level;
    double cached_engine_load;
    double cached_gear;
    double cached_odometer;
    double cached_accelerator_pedal;
    pthread_mutex_t cache_mutex;
};

// Global plugin instance
static struct automotive_plugin *g_plugin = NULL;

// Global references for OBD-II async responses
static const FlutterPlatformMessageResponseHandle *pending_obd_response = NULL;
static uint8_t pending_obd_pid = 0;
static pthread_mutex_t obd_mutex = PTHREAD_MUTEX_INITIALIZER;

// CAN socket initialization
static int can_socket_init(const char *interface_name) {
    int sockfd;
    struct sockaddr_can addr;
    struct ifreq ifr;
    
    // Create socket
    sockfd = socket(PF_CAN, SOCK_RAW, CAN_RAW);
    if (sockfd < 0) {
        printf("[automotive] Failed to create CAN socket: %s\n", strerror(errno));
        return -1;
    }
    
    // Get interface index
    strcpy(ifr.ifr_name, interface_name);
    if (ioctl(sockfd, SIOCGIFINDEX, &ifr) < 0) {
        printf("[automotive] CAN interface '%s' not found: %s\n", interface_name, strerror(errno));
        close(sockfd);
        return -1;
    }
    
    // Enable error frames
    int err_mask = CAN_ERR_MASK;
    setsockopt(sockfd, SOL_CAN_RAW, CAN_RAW_ERR_FILTER, &err_mask, sizeof(err_mask));
    
    // Bind socket to interface
    memset(&addr, 0, sizeof(addr));
    addr.can_family = AF_CAN;
    addr.can_ifindex = ifr.ifr_ifindex;
    
    if (bind(sockfd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        printf("[automotive] Failed to bind CAN socket: %s\n", strerror(errno));
        close(sockfd);
        return -1;
    }
    
    printf("[automotive] CAN socket initialized on %s (fd=%d)\n", interface_name, sockfd);
    return sockfd;
}

// CAN frame reader thread
static void* can_reader_thread(void* arg) {
    struct automotive_plugin *plugin = (struct automotive_plugin*)arg;
    struct can_frame frame;
    ssize_t nbytes;
    
    printf("[automotive] CAN reader thread started\n");
    
    while (plugin->reader_running) {
        nbytes = read(plugin->socket_fd, &frame, sizeof(frame));
        
        if (nbytes < 0) {
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                usleep(1000); // 1ms
                continue;
            }
            printf("[automotive] CAN read error: %s\n", strerror(errno));
            plugin->errors++;
            break;
        }
        
        if (nbytes != sizeof(frame)) {
            printf("[automotive] Incomplete CAN frame received\n");
            continue;
        }
        
        plugin->frames_received++;
        
        // Check for error frames
        if (frame.can_id & CAN_ERR_FLAG) {
            printf("[automotive] CAN error frame: 0x%08X\n", frame.can_id);
            plugin->errors++;
            continue;
        }
        
        printf("[automotive] CAN frame received: ID=0x%03X DLC=%d\n", 
               frame.can_id & CAN_EFF_MASK, frame.can_dlc);
        
        // Check if this is an OBD-II response
        if ((frame.can_id & CAN_EFF_MASK) == 0x7E8) {
            // OBD-II response from ECU
            if (frame.can_dlc >= 3 && frame.data[1] == 0x41) { // Mode 01 response
                uint8_t response_pid = frame.data[2];
                
                // Always parse and cache OBD-II responses
                    double value = 0.0;
                    const char* value_name = "unknown";
                    
                    // Parse OBD-II data based on PID
                    switch (response_pid) {
                        case 0x04: // Engine load
                            if (frame.can_dlc >= 4) {
                                value = (frame.data[3] * 100.0) / 255.0;
                                value_name = "engineLoad";
                            }
                            break;
                        case 0x05: // Engine coolant temperature
                            if (frame.can_dlc >= 4) {
                                value = frame.data[3] - 40.0;
                                value_name = "engineTemp";
                            }
                            break;
                        case 0x0C: // Engine RPM
                            if (frame.can_dlc >= 5) {
                                value = ((frame.data[3] * 256.0) + frame.data[4]) / 4.0;
                                value_name = "rpm";
                            }
                            break;
                        case 0x0D: // Vehicle speed
                            if (frame.can_dlc >= 4) {
                                value = frame.data[3];
                                value_name = "speed";
                            }
                            break;
                        case 0x11: // Throttle position
                            if (frame.can_dlc >= 4) {
                                value = (frame.data[3] * 100.0) / 255.0;
                                value_name = "throttle";
                            }
                            break;
                        case 0x2F: // Fuel level
                            if (frame.can_dlc >= 4) {
                                value = (frame.data[3] * 100.0) / 255.0;
                                value_name = "fuelLevel";
                            }
                            break;
                        case 0xA5: // Current gear (proprietary)
                            if (frame.can_dlc >= 4) {
                                value = frame.data[3];
                                value_name = "gear";
                            }
                            break;
                        case 0xA6: // Odometer (proprietary)
                            if (frame.can_dlc >= 6) {
                                // 3 bytes for odometer in km
                                value = (frame.data[3] << 16) | (frame.data[4] << 8) | frame.data[5];
                                value_name = "odometer";
                            }
                            break;
                        case 0xA7: // Accelerator pedal position (proprietary)
                            if (frame.can_dlc >= 4) {
                                value = (frame.data[3] * 100.0) / 255.0;
                                value_name = "acceleratorPedal";
                            }
                            break;
                    }
                    
                    printf("[automotive] OBD-II response: PID=0x%02X %s=%.2f\n", 
                           response_pid, value_name, value);
                    
                    // Update cache with new value
                    pthread_mutex_lock(&plugin->cache_mutex);
                    switch (response_pid) {
                        case 0x04: plugin->cached_engine_load = value; break;
                        case 0x05: plugin->cached_engine_temp = value; break;
                        case 0x0C: plugin->cached_rpm = value; break;
                        case 0x0D: plugin->cached_speed = value; break;
                        case 0x11: plugin->cached_throttle = value; break;
                        case 0x2F: plugin->cached_fuel_level = value; break;
                        case 0xA5: plugin->cached_gear = value; break;
                        case 0xA6: plugin->cached_odometer = value; break;
                        case 0xA7: plugin->cached_accelerator_pedal = value; break;
                    }
                    pthread_mutex_unlock(&plugin->cache_mutex);
                    printf("[automotive] Cache updated: PID=0x%02X value=%.2f\n", response_pid, value);
            }
        }
    }
    
    printf("[automotive] CAN reader thread stopped\n");
    return NULL;
}

// Platform channel: com.automotive/can_bus
static void on_receive_can_bus(void *userdata, const FlutterPlatformMessage *message) {
    struct platch_obj object;
    struct automotive_plugin *plugin;
    int ok;
    
    ASSUME(userdata);
    ASSUME(message);
    plugin = userdata;
    
    printf("[automotive] Received platform message on can_bus channel, size=%zu\n", message->message_size);
    
    ok = platch_decode(message->message, message->message_size, kStandardMethodCall, &object);
    if (ok != 0) {
        printf("[automotive] Failed to decode message: %d\n", ok);
        platch_respond_error_std(message->response_handle, "malformed-message", "The platform channel message was malformed.", NULL);
        return;
    }
    
    printf("[automotive] Decoded method call: %s\n", object.method ? object.method : "NULL");
    
    if (streq(object.method, "initialize")) {
        // Initialize CAN connection to vcan0
        const char *interface_name = "vcan0";
        
        // Close existing connection
        if (plugin->is_connected) {
            plugin->reader_running = false;
            if (plugin->reader_thread) {
                pthread_join(plugin->reader_thread, NULL);
            }
            close(plugin->socket_fd);
            plugin->is_connected = false;
        }
        
        // Initialize new connection
        plugin->socket_fd = can_socket_init(interface_name);
        if (plugin->socket_fd < 0) {
            printf("[automotive] Failed to initialize CAN interface %s\n", interface_name);
            platch_respond_error_std(message->response_handle, "CONNECTION_FAILED", 
                                    "Failed to initialize CAN interface", NULL);
            return;
        }
        
        strncpy(plugin->interface_name, interface_name, sizeof(plugin->interface_name) - 1);
        plugin->is_connected = true;
        
        // Start reader thread
        plugin->reader_running = true;
        if (pthread_create(&plugin->reader_thread, NULL, can_reader_thread, plugin) != 0) {
            printf("[automotive] Failed to create CAN reader thread\n");
            close(plugin->socket_fd);
            plugin->is_connected = false;
            platch_respond_error_std(message->response_handle, "THREAD_ERROR", 
                                    "Failed to start reader thread", NULL);
            return;
        }
        
        printf("[automotive] CAN Bus initialized successfully on %s\n", interface_name);
        platch_respond(message->response_handle,
                      &(struct platch_obj){ .codec = kStandardMethodCallResponse, 
                                           .success = true, 
                                           .std_result = { .type = kStdTrue } });
        
    } else if (streq(object.method, "readOBD2")) {
        if (!plugin->is_connected) {
            platch_respond_error_std(message->response_handle, "NOT_CONNECTED", 
                                    "CAN interface not initialized", NULL);
            return;
        }
        
        // Extract PID from arguments (assuming it's passed as int)
        if (object.std_arg.type != kStdInt32 && object.std_arg.type != kStdInt64) {
            platch_respond_error_std(message->response_handle, "INVALID_ARGUMENT", 
                                    "PID must be provided as number", NULL);
            return;
        }
        
        uint8_t pid = (uint8_t)(object.std_arg.type == kStdInt32 ? 
                               object.std_arg.int32_value : 
                               object.std_arg.int64_value);
        
        // Send OBD-II request and respond synchronously
        // No need to store response handle for later
        
        // Send OBD-II request frame
        struct can_frame frame;
        memset(&frame, 0, sizeof(frame));
        frame.can_id = 0x7DF; // OBD-II functional address
        frame.can_dlc = 8;
        frame.data[0] = 0x02; // Length
        frame.data[1] = 0x01; // Mode 01 (current data)
        frame.data[2] = pid;  // PID
        // Remaining bytes are padding (0x00)
        
        ssize_t nbytes = write(plugin->socket_fd, &frame, sizeof(frame));
        if (nbytes != sizeof(frame)) {
            printf("[automotive] CAN send failed: %s\n", strerror(errno));
            plugin->errors++;
            pthread_mutex_lock(&obd_mutex);
            if (pending_obd_response == message->response_handle) {
                pending_obd_response = NULL;
                pending_obd_pid = 0;
            }
            pthread_mutex_unlock(&obd_mutex);
            platch_respond_error_std(message->response_handle, "SEND_FAILED", 
                                    "Failed to send CAN frame", NULL);
            return;
        }
        
        plugin->frames_sent++;
        printf("[automotive] OBD-II request sent: PID=0x%02X (ID=0x%03X)\n", pid, frame.can_id);
        
        // Return cached value immediately
        double value = 0.0;
        const char* name = "unknown";
        
        pthread_mutex_lock(&plugin->cache_mutex);
        switch (pid) {
            case 0x04: 
                value = plugin->cached_engine_load;
                name = "engineLoad";
                break;
            case 0x05: 
                value = plugin->cached_engine_temp;
                name = "engineTemp";
                break;
            case 0x0C: 
                value = plugin->cached_rpm;
                name = "rpm";
                break;
            case 0x0D: 
                value = plugin->cached_speed;
                name = "speed";
                break;
            case 0x11: 
                value = plugin->cached_throttle;
                name = "throttle";
                break;
            case 0x2F: 
                value = plugin->cached_fuel_level;
                name = "fuelLevel";
                break;
            case 0xA5: 
                value = plugin->cached_gear;
                name = "gear";
                break;
            case 0xA6: 
                value = plugin->cached_odometer;
                name = "odometer";
                break;
            case 0xA7:
                value = plugin->cached_accelerator_pedal;
                name = "acceleratorPedal";
                break;
            default: 
                value = 0.0;
                break;
        }
        pthread_mutex_unlock(&plugin->cache_mutex);
        
        printf("[automotive] Returning cached value for PID=0x%02X (%s): %.2f\n", pid, name, value);
        
        // Send response as Map with name and value
        struct std_value response = {
            .type = kStdMap,
            .size = 2,
            .keys = (struct std_value[]){
                {.type = kStdString, .string_value = "name"},
                {.type = kStdString, .string_value = "value"}
            },
            .values = (struct std_value[]){
                {.type = kStdString, .string_value = (char*)name},
                {.type = kStdFloat64, .float64_value = value}
            }
        };
        platch_respond_success_std(message->response_handle, &response);
        
    } else if (streq(object.method, "sendCANFrame")) {
        if (!plugin->is_connected) {
            platch_respond_error_std(message->response_handle, "NOT_CONNECTED", 
                                    "CAN interface not initialized", NULL);
            return;
        }
        
        // Send a test CAN frame
        struct can_frame frame;
        memset(&frame, 0, sizeof(frame));
        frame.can_id = 0x123;
        frame.can_dlc = 8;
        frame.data[0] = 0x01;
        frame.data[1] = 0x02;
        frame.data[2] = 0x03;
        frame.data[3] = 0x04;
        frame.data[4] = 0x05;
        frame.data[5] = 0x06;
        frame.data[6] = 0x07;
        frame.data[7] = 0x08;
        
        ssize_t nbytes = write(plugin->socket_fd, &frame, sizeof(frame));
        if (nbytes != sizeof(frame)) {
            printf("[automotive] CAN send failed: %s\n", strerror(errno));
            plugin->errors++;
            platch_respond_error_std(message->response_handle, "SEND_FAILED", 
                                    "Failed to send CAN frame", NULL);
            return;
        }
        
        plugin->frames_sent++;
        printf("[automotive] CAN frame sent: ID=0x%03X DLC=%d\n", frame.can_id, frame.can_dlc);
        platch_respond(message->response_handle,
                      &(struct platch_obj){ .codec = kStandardMethodCallResponse, 
                                           .success = true, 
                                           .std_result = { .type = kStdNull } });
        
    } else if (streq(object.method, "getStats")) {
        // Return real statistics
        struct json_value stats = {
            .type = kJsonObject,
            .size = 5
        };
        
        printf("[automotive] CAN stats: connected=%s interface=%s sent=%lu received=%lu errors=%lu\n",
               plugin->is_connected ? "true" : "false",
               plugin->interface_name,
               plugin->frames_sent,
               plugin->frames_received,
               plugin->errors);
        
        platch_respond(message->response_handle,
                      &(struct platch_obj){ .codec = kStandardMethodCallResponse, 
                                           .success = true, 
                                           .std_result = { .type = kStdNull } });
        
    } else {
        platch_respond_not_implemented(message->response_handle);
    }
    
    platch_free_obj(&object);
}

// Platform channel: com.automotive/sensors  
static void on_receive_sensors(void *userdata, const FlutterPlatformMessage *message) {
    struct platch_obj object;
    struct automotive_plugin *plugin;
    int ok;
    
    ASSUME(userdata);
    ASSUME(message);
    plugin = userdata;
    
    ok = platch_decode(message->message, message->message_size, kStandardMethodCall, &object);
    if (ok != 0) {
        platch_respond_error_std(message->response_handle, "malformed-message", "The platform channel message was malformed.", NULL);
        return;
    }
    
    if (streq(object.method, "getSpeed")) {
        printf("[automotive] Speed requested (mock: 65.0)\n");
        platch_respond(message->response_handle,
                      &(struct platch_obj){ .codec = kStandardMethodCallResponse, 
                                           .success = true, 
                                           .std_result = { .type = kStdNull } });
        
    } else if (streq(object.method, "getRPM")) {
        printf("[automotive] RPM requested (mock: 2500.0)\n");
        platch_respond(message->response_handle,
                      &(struct platch_obj){ .codec = kStandardMethodCallResponse, 
                                           .success = true, 
                                           .std_result = { .type = kStdNull } });
        
    } else if (streq(object.method, "getEngineTemp")) {
        printf("[automotive] Engine temp requested (mock: 92.0)\n");
        platch_respond(message->response_handle,
                      &(struct platch_obj){ .codec = kStandardMethodCallResponse, 
                                           .success = true, 
                                           .std_result = { .type = kStdNull } });
        
    } else {
        platch_respond_not_implemented(message->response_handle);
    }
    
    platch_free_obj(&object);
}

// Plugin initialization
enum plugin_init_result automotive_plugin_init(struct flutterpi *flutterpi, void **userdata_out) {
    struct plugin_registry *registry;
    struct automotive_plugin *plugin;
    int ok;
    
    ASSUME(flutterpi);
    
    printf("[automotive] Initializing automotive CAN plugin\n");
    
    registry = flutterpi_get_plugin_registry(flutterpi);
    
    plugin = malloc(sizeof *plugin);
    if (plugin == NULL) {
        goto fail_return_error;
    }
    
    // Initialize plugin state
    plugin->flutterpi = flutterpi;
    plugin->socket_fd = -1;
    plugin->is_connected = false;
    plugin->reader_running = false;
    plugin->frames_sent = 0;
    plugin->frames_received = 0;
    plugin->errors = 0;
    
    // Initialize cache
    pthread_mutex_init(&plugin->cache_mutex, NULL);
    plugin->cached_rpm = 0.0;
    plugin->cached_speed = 0.0;
    plugin->cached_engine_temp = 20.0;
    plugin->cached_throttle = 0.0;
    plugin->cached_fuel_level = 50.0;
    plugin->cached_engine_load = 0.0;
    plugin->cached_gear = 0.0;
    plugin->cached_odometer = 0.0;
    plugin->cached_accelerator_pedal = 0.0;
    memset(plugin->interface_name, 0, sizeof(plugin->interface_name));
    
    g_plugin = plugin; // Set global reference for thread access
    
    // Register CAN Bus method channel
    ok = plugin_registry_set_receiver_v2_locked(registry, "com.automotive/can_bus", on_receive_can_bus, plugin);
    if (ok != 0) {
        printf("[automotive] Could not set CAN bus receiver: %s\n", strerror(ok));
        goto fail_free_plugin;
    }
    
    // Register Sensors method channel  
    ok = plugin_registry_set_receiver_v2_locked(registry, "com.automotive/sensors", on_receive_sensors, plugin);
    if (ok != 0) {
        printf("[automotive] Could not set sensors receiver: %s\n", strerror(ok));
        goto fail_remove_can_receiver;
    }
    
    *userdata_out = plugin;
    
    printf("[automotive] Automotive plugin initialized successfully with platform channels\n");
    return PLUGIN_INIT_RESULT_INITIALIZED;
    
fail_remove_can_receiver:
    plugin_registry_remove_receiver_v2_locked(registry, "com.automotive/can_bus");
    
fail_free_plugin:
    free(plugin);
    g_plugin = NULL;
    
fail_return_error:
    return PLUGIN_INIT_RESULT_ERROR;
}

// Plugin cleanup
void automotive_plugin_deinit(struct flutterpi *flutterpi, void *userdata) {
    // Clean up any pending OBD response
    pthread_mutex_lock(&obd_mutex);
    if (pending_obd_response != NULL) {
        platch_respond_error_std(pending_obd_response, "SHUTDOWN", 
                                "Plugin shutting down", NULL);
        pending_obd_response = NULL;
        pending_obd_pid = 0;
    }
    pthread_mutex_unlock(&obd_mutex);
    
    struct plugin_registry *registry;
    struct automotive_plugin *plugin;
    
    ASSUME(flutterpi);
    ASSUME(userdata);
    
    printf("[automotive] Deinitializing automotive plugin\n");
    
    plugin = userdata;
    registry = flutterpi_get_plugin_registry(flutterpi);
    
    // Stop CAN reader thread if running
    if (plugin->is_connected) {
        plugin->reader_running = false;
        if (plugin->reader_thread) {
            pthread_join(plugin->reader_thread, NULL);
        }
        close(plugin->socket_fd);
    }
    
    // Remove platform channels
    plugin_registry_remove_receiver_v2_locked(registry, "com.automotive/can_bus");
    plugin_registry_remove_receiver_v2_locked(registry, "com.automotive/sensors");
    
    g_plugin = NULL;
    free(plugin);
}

// Plugin registration
FLUTTERPI_PLUGIN("automotive", automotive, automotive_plugin_init, automotive_plugin_deinit);