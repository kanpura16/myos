const trb = @import("trb.zig");
const console = @import("../../../console.zig");

pub var cmd_ring: Ring = Ring{};
// pub var transfer_ring: Ring align(64) = Ring{};
pub var prim_event_ring: EventRing = .{};
pub var event_ring_segment_table: [1]EventRingSegment align(64) = undefined;

const EventRingSegment = packed struct(u128) {
    _resv1: u6 = 0,
    ring_segment_ptr: u58,
    ring_segment_size: u16,
    _resv2: u48 = 0,
};

const Ring = struct {
    trbs: [64]u128 align(64) = undefined,
    enqueue_ptr: usize = 0,
    cycle_bit: u1 = 1,

    pub fn push(self: *@This(), elem_trb: *u128) void {
        self.trbs[self.enqueue_ptr] = blk: {
            const tmp_trb: *trb.Trb = @ptrCast(elem_trb);
            tmp_trb.field.cycle_bit = self.cycle_bit;

            break :blk tmp_trb.value;
        };

        self.enqueue_ptr += 1;
        if (self.enqueue_ptr == self.trbs.len - 1) {
            self.trbs[self.enqueue_ptr] = blk: {
                var link_trb = trb.LinkTrb{ .field = .{} };
                link_trb.field.ring_segment_ptr = @intCast(@intFromPtr(&self.trbs[0]) >> 4);
                link_trb.field.cycle_bit = self.cycle_bit;
                link_trb.field.toggle_cycle = 1;

                break :blk link_trb.value;
            };

            self.enqueue_ptr = 0;
            self.cycle_bit = ~self.cycle_bit;
        }
    }
};

const EventRing = struct {
    trbs: [64]u128 align(64) = undefined,
    dequeue_idx: usize = 0,
    int_reg_dequeue_ptr: *volatile u60 = undefined,
    cycle_bit: u1 = 1,

    pub fn pop(self: *@This()) ?u128 {
        const elem_trb: *const trb.Trb = @ptrCast(&self.trbs[self.dequeue_idx]);

        defer if (elem_trb.field.cycle_bit == self.cycle_bit) {
            self.dequeue_idx += 1;
            self.int_reg_dequeue_ptr.* += 16;
            if (self.dequeue_idx == self.trbs.len) {
                self.dequeue_idx = 0;
                self.int_reg_dequeue_ptr.* = @intCast(@intFromPtr(&self.trbs[0]) >> 4);
                self.cycle_bit = ~self.cycle_bit;
            }
        };

        return blk: {
            if (elem_trb.field.cycle_bit == self.cycle_bit) {
                break :blk self.trbs[self.dequeue_idx];
            } else {
                break :blk null;
            }
        };
    }
};
