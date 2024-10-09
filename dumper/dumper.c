/* SPDX-License-Identifier: Apache-2.0 */

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <types.h>

#include <log.h>

#include <common.h>

#include <mmu.h>

#include <cli.h>
#include <cli_shell.h>
#include <cli_termesc.h>

#include <sys-dram.h>
#include <sys-gpio.h>
#include <sys-i2c.h>
#include <sys-sdcard.h>
#include <sys-sid.h>
#include <sys-spi.h>
#include <sys-uart.h>

extern sunxi_serial_t uart_dbg;

extern sunxi_i2c_t i2c_pmu;

extern sunxi_sdhci_t sdhci2;

extern uint32_t dram_para[32];

static uint32_t *offset_ptr = (uint32_t*)(0x40000 + 0x4a50);
static uint32_t *offset_ptr2 = (uint32_t*)(0x40000 + 0x4a54);
static uint8_t *read_buffer_start = (uint8_t*)(0x40000 + 0x4a50 + 0x9b0);
static uint8_t *read_buffer = (uint8_t*)(0x40000 + 0x4a50 + 0x9b4);

// 96 * 0x200 = 0xc000 bytes total will be dumped
#define LOOP_CNT 96

int cmd_read() {
    if (*offset_ptr2 != 0x57357357) {
        *offset_ptr2 = 0x57357357;
        *offset_ptr = 0;
    }

    memset(read_buffer, 0x57, 512 * LOOP_CNT);

    *read_buffer_start = *offset_ptr;

    for (int i = 0; i < LOOP_CNT; i++) {
        uint32_t cur_block = *offset_ptr;
        sdmmc_blk_read(&card0, read_buffer + (512 * i), cur_block, 1);
        cur_block++;
        *offset_ptr = cur_block;
    }

    return 0;
}

int main(void) {
    sunxi_clk_init();

    sunxi_clk_dump();

    sunxi_i2c_init(&i2c_pmu);

    pmu_axp1530_init(&i2c_pmu);

    enable_sram_a3();

    printk_info("DRAM: DRAM Size = %dMB\n", sunxi_dram_init(&dram_para));

    sunxi_clk_dump();

    /* Initialize the SD host controller. */
    if (sunxi_sdhci_init(&sdhci2) != 0) {
        printk_error("SMHC: %s controller init failed\n", sdhci2.name);
    } else {
        printk_info("SMHC: %s controller initialized\n", sdhci2.name);
    }

    /* Initialize the SD card and check if initialization is successful. */
    if (sdmmc_init(&card0, &sdhci2) != 0) {
        printk_warning("SMHC: init failed\n");
    } else {
        printk_debug("Card OK!\n");
    }

    cmd_read();

    return 0;
}