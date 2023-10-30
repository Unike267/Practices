# WARNING!

--

When compiling main.c the fuction "neorv32_slink_available()" is used and in the [library](https://github.com/stnolting/neorv32/blob/main/sw/lib/source/neorv32_slink.c) of that function there is a bug. It's written (line 51) "if (NEORV32_SYSINFO->SOC & (1 << SYSINFO_SOC_IO_SDI))" when the correct form is "if (NEORV32_SYSINFO->SOC & (1 << SYSINFO_SOC_IO_SLINK))". 

--

### Result:

**The result obtained by the CuteCom terminal is shown:**

![](https://raw.githubusercontent.com/Unike267/Photos/master/UNI-Photos/Practices/CUTECOM.png)

--

**NOTES:**

*Note 1: the application image is made with the library corrected.*

*Note 2: make pull request and delete this README.*




