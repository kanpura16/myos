pub var dev_context_base_addr_arr: [256]*DeviceContext align(64) = undefined;

pub const DeviceContext = packed struct {
    slot_context: SlotContext,
    endpoint_contexts: [31]EndpointContext,
};

pub const SlotContext = packed struct {
    route_string: u20,
    speed: u4,
    _resv1: u1,
    multi_tt: u1,
    hub: u1,
    context_entries: u5,
    max_exit_latency: u16,
    root_hub_port_num: u8,
    num_ports: u8,
    parent_hub_slot_id: u8,
    parent_port_num: u8,
    tt_think_time: u2,
    _resv2: u4,
    interrupter_target: u10,
    usb_dev_addr: u8,
    _resv3: u19,
    slot_state: u5,
};

pub const EndpointContext = packed struct {
    endpoint_state: u3,
    _resv1: u5,
    mult: u2,
    max_primary_streams: u5,
    linear_stream_arr: u1,
    interval: u8,
    max_endpoint_service_time_interval_payload_high: u8,
    _resv2: u1,
    err_count: u2,
    endpoint_type: u3,
    _resv3: u1,
    host_initiate_disable: u1,
    max_burst_size: u8,
    max_packet_size: u16,
    dequeue_cycle_state: u1,
    _resv4: u3,
    tr_dequeue_pointer: u60,
    average_trb_len: u16,
    max_endpoint_service_time_interval_payload_low: u16,
};

pub const DevContextBaseAddrArrPtr = packed struct {
    _resv: u6,
    dev_context_base_addr_arr_ptr: u58,
};

pub const ScratchpadBufArrElem4kPageSize = packed struct {
    _resv: u12,
    scratchpad_buf_addr: u52,
};
