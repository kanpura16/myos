pub const Trb = extern union {
    value: u128,
    field: packed struct(u128) {
        data_ptr: u64 = 0,
        transfer_len: u17 = 0,
        td_size: u5 = 0,
        interrupter_target: u10 = 0,
        cycle_bit: u1 = 0,
        eval_next: u1 = 0,
        interrupt_on_short_packet: u1 = 0,
        no_snoop: u1 = 0,
        chain_bit: u1 = 0,
        interrupt_on_completion: u1 = 0,
        immediate_data: u1 = 0,
        _resv1: u2 = 0,
        block_event_interrupt: u1 = 0,
        type: u6 = 1,
        _resv2: u16 = 0,
    },
};

pub const LinkTrb = extern union {
    value: u128,
    field: packed struct(u128) {
        _resv1: u4 = 0,
        ring_segment_ptr: u60 = 0,
        _resv2: u22 = 0,
        interrupt_target: u10 = 0,
        cycle_bit: u1 = 0,
        toggle_cycle: u1 = 0,
        _resv3: u2 = 0,
        chain_bit: u1 = 0,
        interrupt_on_completion: u1 = 0,
        _resv4: u4 = 0,
        type: u6 = 6,
        _resv5: u16 = 0,
    },
};
