#!/usr/bin/env python3
import sys
import os

def bin_to_vh(bin_path, vh_path):
    if not os.path.exists(bin_path):
        print(f"Error: {bin_path} does not exist.")
        return
    with open(bin_path, "rb") as f:
        data = f.read()

    # Pad to 4-byte boundary
    if len(data) % 4 != 0:
        data += b'\x00' * (4 - (len(data) % 4))

    num_words = len(data) // 4
    with open(vh_path, "w") as f:
        f.write("// =============================================================================\n")
        f.write(f"// Auto-generated firmware loader from {os.path.basename(bin_path)}\n")
        f.write(f"// Total Instructions / Words: {num_words} (Size: {len(data)} bytes)\n")
        f.write("// =============================================================================\n\n")
        f.write("task automatic load_c_firmware();\n")
        f.write("    $display(\"[FIRMWARE] Loading compiled C binary (%0d words)...\", " + str(num_words) + ");\n")
        for i in range(0, len(data), 4):
            word = data[i] | (data[i+1] << 8) | (data[i+2] << 16) | (data[i+3] << 24)
            f.write(f"    write_imem_word({i//4:4d}, 32'h{word:08x});\n")
        f.write("endtask\n")

    print(f"Successfully generated {vh_path} with {num_words} words.")

if __name__ == "__main__":
    bin_file = sys.argv[1] if len(sys.argv) > 1 else "hello_world.bin"
    vh_file  = sys.argv[2] if len(sys.argv) > 2 else "firmware_words.vh"
    bin_to_vh(bin_file, vh_file)
