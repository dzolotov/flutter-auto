/*
 * Flutter-Pi Automotive CAN Bus Plugin Header
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
 * Supports SocketCAN (can0, vcan0) and OBD-II protocols
 */

#ifndef AUTOMOTIVE_PLUGIN_H
#define AUTOMOTIVE_PLUGIN_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// CAN frame structure compatible with SocketCAN
typedef struct {
    uint32_t id;          // CAN ID
    uint8_t dlc;          // Data length
    uint8_t data[8];      // Payload
    uint64_t timestamp;   // Timestamp μs
    bool extended;        // 29-bit ID
    bool rtr;            // Remote frame
} can_frame_t;

// OBD-II PID definitions
#define OBD2_ENGINE_TEMP    0x05
#define OBD2_ENGINE_RPM     0x0C
#define OBD2_VEHICLE_SPEED  0x0D
#define OBD2_ENGINE_LOAD    0x04
#define OBD2_THROTTLE_POS   0x11
#define OBD2_FUEL_LEVEL     0x2F

// CAN interface functions
int can_socket_init(const char *interface_name);
int can_send_frame(int sockfd, const can_frame_t *frame);
int can_recv_frame(int sockfd, can_frame_t *frame);
void can_socket_cleanup(int sockfd);

// OBD-II helper functions
int obd2_request_pid(int sockfd, uint8_t pid);
double obd2_parse_response(const uint8_t *data, uint8_t len, uint8_t pid);

// Plugin lifecycle
int automotive_plugin_init(void);
void automotive_plugin_deinit(void);

#ifdef __cplusplus
}
#endif

#endif // AUTOMOTIVE_PLUGIN_H