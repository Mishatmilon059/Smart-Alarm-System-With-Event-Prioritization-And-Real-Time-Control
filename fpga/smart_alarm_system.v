module smart_alarm_system (
    input clk,
    input reset,

    input sensor_in,   // Fire sensor (PMOD JA1)
    input door,        // SW0
    input motion,      // SW1

    output reg [2:0] led
);

    parameter IDLE         = 2'b00;
    parameter DOOR_ALARM   = 2'b01;
    parameter MOTION_ALARM = 2'b10;
    parameter FIRE_ALARM   = 2'b11;

    reg [1:0] state;
    reg [1:0] next_state;

    // ==================================================
    // State register
    // ==================================================
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    // ==================================================
    // Next-state logic (Priority: Fire > Motion > Door)
    // ==================================================
    always @(*) begin
        case (state)

            IDLE:
                if (sensor_in)         // Fire sensor
                    next_state = FIRE_ALARM;
                else if (motion)
                    next_state = MOTION_ALARM;
                else if (door)
                    next_state = DOOR_ALARM;
                else
                    next_state = IDLE;

            DOOR_ALARM:
                if (sensor_in)
                    next_state = FIRE_ALARM;
                else if (motion)
                    next_state = MOTION_ALARM;
                else
                    next_state = DOOR_ALARM;

            MOTION_ALARM:
                if (sensor_in)
                    next_state = FIRE_ALARM;
                else
                    next_state = MOTION_ALARM;

            FIRE_ALARM:
                next_state = FIRE_ALARM;

            default:
                next_state = IDLE;
        endcase
    end

    // ==================================================
    // Output logic (Moore)
    // ==================================================
    always @(*) begin
        case (state)
            IDLE:         led = 3'b000;
            DOOR_ALARM:   led = 3'b001;
            MOTION_ALARM: led = 3'b010;
            FIRE_ALARM:   led = 3'b100;
            default:      led = 3'b000;
        endcase
    end

endmodule
