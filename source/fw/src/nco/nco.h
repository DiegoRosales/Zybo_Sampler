#ifndef NCO_H
#define NCO_H


#define FRACTION_SIZE 23 // Bits
#define SIZE_OF_SINE_LUT 512


// Audio Data structure
typedef struct {
    uint32_t left_channel;
    uint32_t right_channel;
} audio_data_t;

// NCO structure
typedef struct nco_struct {
    audio_data_t * audio_data;
    uint32_t       target_memory_size;
    uint32_t       accumulator;
    float          frequency;
    uint32_t       phase;
} nco_t;

void nco_init(nco_t * nco, uint32_t frequency, uint32_t sample_frequency);
void nco_load_sine_to_mem(nco_t *nco);
float nco_normalize_frequency(uint32_t frequency, uint32_t sample_frequency);
uint32_t nco_phase_init(float frequency_norm);

#endif
