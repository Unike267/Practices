# Run implementation with nextpnr

📢 The implementation is performed with the following container: 📢

- `ghcr.io/unike267/containers/impl-arty:latest` 

    - This container has: `GHDL + yosys + GHDL yosys plugin + nextpnr-xilinx + prjxray` to perform `synthesis + implementation + generate bitstream` on the boards:
        - `Arty A7 35t`
        - `Arty A7 100t`

This container is built 🔨 and pushed 📤 through continuous integration ♻️ in the following repository:

- `Unike267/Containers`

The resulting bitstreams are uploaded as **artifacts**, you can go to the `actions` associated with continuous integration of the implementation and download them.

I recommend using [openFPGALoader](https://github.com/trabucayre/openFPGALoader) to load bitstreams. The comand to load a bitstream for `ARTY` boards (both the `100t` and the `35t`) is as follows:

- `openFPGALoader --board arty name_of_bitstream.bit`
