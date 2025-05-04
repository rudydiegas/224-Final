import os
import logging
import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import *

USB_J   = 0b10
USB_K   = 0b01
USB_SE0 = 0b00
SYNC = [USB_K, USB_J, USB_K, USB_J, USB_K, USB_J, USB_K, USB_K]
EOP = [USB_SE0, USB_SE0, USB_J]

@cocotb.test()
async def handshake_test(dut):
    print("============== STARTING HANDSHAKE TEST ==============")

    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    dut.rst_n.value = 0
    dut.en.value = 1
    dut.serial_in.value = USB_J
    await RisingEdge(dut.clk)

    dut.rst_n.value = 1
    for i in range(10):
        await RisingEdge(dut.clk)

    packet = SYNC.copy()
    packet += [USB_J, USB_J, USB_K, USB_J] # ACK PID
    packet += [USB_J, USB_K, USB_K, USB_K] # ACK PID_n
    packet += EOP

    for val in packet:
        dut.serial_in.value = val
        await RisingEdge(dut.clk)

    await RisingEdge(dut.end_transmission)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    assert dut.rcvd_sync.value == 0x1
    assert dut.PID_val.value == 0x2
    assert dut.PID_val_n.value == 0xD
    assert dut.error.value == 0

    print("============== ENDING HANDSHAKE TEST ==============")

@cocotb.test()
async def data_test(dut):
    print("============== STARTING DATA TEST ==============")

    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    dut.rst_n.value = 0
    dut.en.value = 1
    dut.serial_in.value = USB_J
    await RisingEdge(dut.clk)

    dut.rst_n.value = 1
    for i in range(10):
        await RisingEdge(dut.clk)

    packet = SYNC.copy()
    packet += [USB_K, USB_K, USB_J, USB_K] # DATA0 PID
    packet += [USB_J, USB_K, USB_K, USB_K] # DATA0 PID_n
    packet += [USB_J, USB_K, USB_J, USB_J, USB_J, USB_K, USB_K, USB_K,
               USB_J, USB_J, USB_J, USB_K, USB_K, USB_K, USB_K, USB_K,
               USB_K, USB_J, USB_J, USB_J, USB_K, USB_K, USB_J, USB_K,
               USB_J, USB_K, USB_J, USB_J, USB_K, USB_K, USB_K, USB_J,
               USB_J, USB_J, USB_J, USB_K, USB_K, USB_K, USB_J, USB_J,
               USB_J, USB_K, USB_J, USB_K, USB_K, USB_J, USB_K, USB_J,
               USB_K, USB_K, USB_J, USB_J, USB_K, USB_K, USB_J, USB_J,
               USB_K, USB_J, USB_K, USB_J, USB_K, USB_J, USB_J, USB_K,
               USB_J, USB_J, USB_K, USB_K, USB_J, USB_K, USB_K, USB_J,
               USB_K, USB_J, USB_J, USB_K, USB_K, USB_J, USB_J, USB_K]
    packet += EOP

    for val in packet:
        dut.serial_in.value = val
        await RisingEdge(dut.clk)

    await RisingEdge(dut.end_transmission)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    assert dut.rcvd_sync.value == 0x1
    assert dut.PID_val.value == 0x3
    assert dut.PID_val_n.value == 0xC
    assert dut.rcvd_data == 0x40aa11b7682df6d8
    assert dut.error.value == 0

    print("============== ENDING DATA TEST ==============")

@cocotb.test()
async def data_zero_test(dut):
    print("============== STARTING DATA ZERO TEST ==============")

    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    dut.rst_n.value = 0
    dut.en.value = 1
    dut.serial_in.value = USB_J
    await RisingEdge(dut.clk)

    dut.rst_n.value = 1
    for i in range(10):
        await RisingEdge(dut.clk)

    packet = SYNC.copy()
    packet += [USB_K, USB_K, USB_J, USB_K] # DATA0 PID
    packet += [USB_J, USB_K, USB_K, USB_K] # DATA0 PID_n
    packet += [USB_J, USB_K, USB_J, USB_K, USB_J, USB_K, USB_J, USB_K,
               USB_J, USB_K, USB_J, USB_K, USB_J, USB_K, USB_J, USB_K,
               USB_J, USB_K, USB_J, USB_K, USB_J, USB_K, USB_J, USB_K,
               USB_J, USB_K, USB_J, USB_K, USB_J, USB_K, USB_J, USB_K,
               USB_J, USB_K, USB_J, USB_K, USB_J, USB_K, USB_J, USB_K,
               USB_J, USB_K, USB_J, USB_K, USB_J, USB_K, USB_J, USB_K,
               USB_J, USB_K, USB_J, USB_K, USB_J, USB_K, USB_J, USB_K,
               USB_J, USB_K, USB_J, USB_K, USB_J, USB_K, USB_J, USB_K] # DATA
    packet += [USB_K, USB_K, USB_K, USB_K, USB_K, USB_K, USB_J, USB_K, USB_K,
               USB_J, USB_K, USB_K, USB_J, USB_J, USB_J, USB_J, USB_J] # CRC FD2F
                                                            # 1111 1101 0010 1111
    packet += EOP

    for val in packet:
        dut.serial_in.value = val
        await RisingEdge(dut.clk)

    await RisingEdge(dut.end_transmission)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    assert dut.rcvd_sync.value == 0x1
    assert dut.PID_val.value == 0x3
    assert dut.PID_val_n.value == 0xC
    assert dut.rcvd_data == 0
    assert dut.error.value == 0

    print("============== ENDING DATA ZERO TEST ==============")

@cocotb.test()
async def data_one_test(dut):
    print("============== STARTING DATA ONE TEST ==============")

    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    dut.rst_n.value = 0
    dut.en.value = 1
    dut.serial_in.value = USB_J
    await RisingEdge(dut.clk)

    dut.rst_n.value = 1
    for i in range(10):
        await RisingEdge(dut.clk)

    packet = SYNC.copy()
    packet += [USB_K, USB_K, USB_J, USB_K] # DATA0 PID
    packet += [USB_J, USB_K, USB_K, USB_K] # DATA0 PID_n
    packet += [USB_J, USB_K, USB_J, USB_K, USB_J, USB_K, USB_J, USB_K,
               USB_J, USB_K, USB_J, USB_K, USB_J, USB_K, USB_J, USB_K,
               USB_J, USB_K, USB_J, USB_K, USB_J, USB_K, USB_J, USB_K,
               USB_J, USB_K, USB_J, USB_K, USB_J, USB_K, USB_J, USB_K,
               USB_J, USB_K, USB_J, USB_K, USB_J, USB_K, USB_J, USB_K,
               USB_J, USB_K, USB_J, USB_K, USB_J, USB_K, USB_J, USB_K,
               USB_J, USB_K, USB_J, USB_K, USB_J, USB_K, USB_J, USB_K,
               USB_K, USB_J, USB_K, USB_J, USB_K, USB_J, USB_K, USB_J] # DATA
    packet += [USB_K, USB_K, USB_K, USB_K, USB_K, USB_K, USB_K, USB_J, USB_K,
               USB_J, USB_K, USB_K, USB_J, USB_J, USB_J, USB_K, USB_J] # CRC 7E2C
                                                            # 0111 1110 0010 1100
    packet += EOP

    for val in packet:
        dut.serial_in.value = val
        await RisingEdge(dut.clk)

    await RisingEdge(dut.end_transmission)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    assert dut.rcvd_sync.value == 0x1
    assert dut.PID_val.value == 0x3
    assert dut.PID_val_n.value == 0xC
    assert dut.rcvd_data == 0x0100000000000000
    assert dut.error.value == 0

    print("============== ENDING DATA ONE TEST ==============")

@cocotb.test()
async def bitstuff_test(dut):
    print("============== STARTING BITSTUFF TEST ==============")

    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    dut.rst_n.value = 0
    dut.en.value = 1
    dut.serial_in.value = USB_J
    await RisingEdge(dut.clk)

    dut.rst_n.value = 1
    for i in range(10):
        await RisingEdge(dut.clk)

    packet = SYNC.copy()
    packet += [USB_K, USB_K, USB_J, USB_K] # DATA0 PID
    packet += [USB_J, USB_K, USB_K, USB_K] # DATA0 PID_n
    packet += [USB_J, USB_K, USB_J, USB_J, USB_J, USB_K, USB_K, USB_K,
               USB_J, USB_J, USB_J, USB_K, USB_K, USB_K, USB_K, USB_K,
               USB_K, USB_K, USB_J, USB_J, USB_J, USB_K, USB_K, USB_J, USB_K,
               USB_J, USB_K, USB_J, USB_J, USB_K, USB_K, USB_K, USB_J,
               USB_J, USB_J, USB_J, USB_K, USB_K, USB_K, USB_J, USB_J,
               USB_J, USB_K, USB_J, USB_K, USB_K, USB_J, USB_K, USB_J,
               USB_K, USB_K, USB_J, USB_J, USB_K, USB_K, USB_J, USB_J,
               USB_K, USB_J, USB_K, USB_J, USB_K, USB_J, USB_J, USB_K] # DATA
    packet += [USB_K, USB_K, USB_J, USB_J, USB_K, USB_J, USB_J, USB_K,
               USB_J, USB_J, USB_J, USB_K, USB_K, USB_K, USB_J, USB_J] # CRC D26D
                                                            # 1101 0010 0110 1101
    packet += EOP

    for val in packet:
        dut.serial_in.value = val
        await RisingEdge(dut.clk)

    await RisingEdge(dut.end_transmission)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    assert dut.rcvd_sync.value == 0x1
    assert dut.PID_val.value == 0x3
    assert dut.PID_val_n.value == 0xC
    assert dut.rcvd_data == 0x40aa11b7682ff6d8
    assert dut.error.value == 0

    print("============== ENDING BITSTUFF TEST ==============")
