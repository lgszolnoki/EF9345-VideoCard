# EF9345-VideoCard
EF9345 based RCBus compatible video card with VGA output targeting RomWBW. 
I have used the following sources, among others:
  https://github.com/EtchedPixels
    https://stardot.org.uk/forums/viewtopic.php?t=22941
  https://hackaday.io/project/182424-ef9365-ef9366-ef9367-video
  https://hackaday.io/project/189225-80-column-video-for-rc2014

## Hardware
This simple video card provides a VGA compatible output for 24x80 or 24x40 text display formats. The PCB design is done by Eagle. The board was manufactured by JLCPCB. For the addressing I prefere to use PLDs. Attached the souce code as well as the JEDEC file.
## Software
The card can be configured for 40 x 24 or 80 x 24 text display. However, the resolution of 40 x 24 is not suitable for RomWBW. The 80 x 24 resolution is fine for most applications. The driver has some obstacles in connection with the scrolling function. WS and ZDE show strange behavior when scrolling up linewise, but page up and down works fine. 
### Contributions are welcome to fix the problem.
