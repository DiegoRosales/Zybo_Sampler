
#ifndef CODEC_UTILS_H
#define CODEC_UTILS_H

#define BUSY_BIT 2


int CodecRd(int addr, int display, int debug);
int CodecWr(int addr, int data, int check, int display, int debug);
void BusyBitIsClear(int debug);
void ControllerReset(int debug);
void ClearStatusBits(int debug);
void WaitUntilDataIsAvailable(int debug);
void CodecInit(int debug);
void CodecReset(int debug);
int SetOutputVolume(int volume);
int SetInputVolume(int volume);

#endif
