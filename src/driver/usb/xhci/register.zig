const context = @import("context.zig");

pub const CapabilityReg = packed struct(u256) {
    cap_len: u8,
    _resv1: u8,
    hciverrsion: u16,
    hcsparams1: Hcsparams1,
    hcsparams2: Hcsparams2,
    hcsparams3: u32,
    hccparams1: u32,
    doorbell_off: u32,
    runtime_reg_off: u32,
    hccparams2: u32,

    pub const Hcsparams1 = packed struct(u32) {
        max_slots: u8,
        max_interrupters: u11,
        _resv: u5,
        max_ports: u8,
    };

    pub const Hcsparams2 = packed struct(u32) {
        isochronous_scheduling_threshold: u4,
        event_ring_segment_table_max: u4,
        _resv: u13,
        max_scratchpad_bufs_hi: u5,
        scratchpad_restore: u1,
        max_scratchpad_bufs_lo: u5,
    };
};

pub const OperationalReg = packed struct(u480) {
    usb_cmd: UsbCmdReg,
    usb_status: UsbStatusReg,
    page_size: u32,
    _resv1: u64,
    dev_notification_ctrl: u32,
    cmd_ring_ctrl: CmdRingCtrl,
    _resv2: u134,
    dev_context_base_addr_arr_ptr: u58,
    config: ConfigReg,

    pub const UsbCmdReg = packed struct(u32) {
        run_stop: u1,
        host_controller_reset: u1,
        interrupter_enable: u1,
        host_sys_err_enable: u1,
        _resv1: u3,
        light_host_controller_reset: u1,
        controller_save_state: u1,
        controller_restore_state: u1,
        enable_wrap_event: u1,
        enable_u3_mfindex_stop: u1,
        _resv2: u1,
        cem_enable: u1,
        extended_tbc_enable: u1,
        extended_tbc_status_enable: u1,
        vtio_enable: u1,
        _resv3: u15,
    };

    pub const UsbStatusReg = packed struct(u32) {
        host_controller_halted: u1,
        _resv1: u1,
        host_sys_err: u1,
        event_interrupt: u1,
        port_change_detect: u1,
        _resv2: u3,
        save_state_status: u1,
        restore_state_status: u1,
        save_restore_err: u1,
        controller_not_ready: u1,
        host_controller_err: u1,
        _resv3: u19,
    };

    pub const CmdRingCtrl = packed struct(u64) {
        ring_cycle_state: u1,
        cmd_stop: u1,
        cmd_abort: u1,
        cmd_ring_running: u1,
        _resv: u2,
        cmd_ring_ptr: u58,
    };

    pub const ConfigReg = packed struct(u32) {
        max_dev_slots: u8,
        u3_entry_enable: u1,
        config_info_enable: u1,
        _resv: u22,
    };
};

pub const RuntimeReg = packed struct {
    microframe_idx: u14,
    _resv: u242,
    interrupt_reg_set1: InterruptRegSet,

    pub const InterruptRegSet = packed struct(u256) {
        interrupt_pending: u1,
        interrupt_enable: u1,
        _resv1: u30,
        interrupt_moderation_interval: u16,
        interrupt_moderation_counter: u16,
        event_ring_segment_table_size: u16,
        _resv2: u54,
        event_ring_segment_table_ptr: u58,
        dequeue_erst_segment_idx: u3,
        event_handler_busy: u1,
        event_ring_dequeue_ptr: u60,
    };
};
