const trb = @import("trb.zig");
const console = @import("../../../console.zig");

pub var cmd_ring: Ring = Ring{};
// pub var transfer_ring: Ring align(64) = Ring{};
pub var prim_event_ring: EventRing = EventRing{};

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

pub var event_ring_segment_table: [1]EventRingSegment align(64) = undefined;

const EventRingSegment = packed struct(u128) {
    _resv1: u6 = 0,
    ring_segment_ptr: u58,
    ring_segment_size: u16,
    _resv2: u48 = 0,
};

const EventRing = struct {
    trbs: [64]u128 align(64) = undefined,
    dequeue_ptr: usize = 0,
    cycle_bit: u1 = 1,

    pub fn pop(self: *@This()) ?u128 {
        const old_dequeue_ptr = self.dequeue_ptr;
        const old_cycle_bit = self.cycle_bit;

        self.dequeue_ptr += 1;
        if (self.dequeue_ptr == self.trbs.len) {
            self.dequeue_ptr = 0;
            ~self.cycle_bit;
        }

        return blk: {
            const elem_trb: *const trb.Trb = @ptrCast(&self.trbs[old_dequeue_ptr]);
            if (elem_trb.field.cycle_bit == old_cycle_bit) {
                break :blk self.trbs[old_dequeue_ptr];
            } else {
                break :blk null;
            }
        };
    }
};
