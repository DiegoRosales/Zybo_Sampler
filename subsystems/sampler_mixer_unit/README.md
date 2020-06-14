# Sampler Mixer Unit

On a high-level, this module takes the a stream of samples that should be mixed together and outputs a stream of mixed samplea

The samples come through an AXI-S interface in a "serialized form".

For example: If you're playing 3 keys at the same time. This module will receive the samples of each key separately and will not make the output available until the last key has been received

The module will know when the last key has been received by checking bit 6 in the TUSER signal of the AXI Stream interface. The boundries of each sample are determined by the TLAST signal.