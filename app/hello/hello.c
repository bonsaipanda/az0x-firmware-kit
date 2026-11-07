/* hello: proves the image boots into an app and that ALSA sees the
 * device's sound cards and MIDI ports. Prints to the console (tty1 and
 * serial) and the log, then idles. */
#include <alsa/asoundlib.h>
#include <stdio.h>
#include <unistd.h>

static void list_cards(void)
{
    int card = -1;
    while (snd_card_next(&card) == 0 && card >= 0) {
        char *name = NULL, *longname = NULL;
        snd_card_get_name(card, &name);
        snd_card_get_longname(card, &longname);
        printf("  card %d: %s (%s)\n", card, name ? name : "?",
               longname ? longname : "?");
        free(name);
        free(longname);
    }
}

static void list_rawmidi(void)
{
    int card = -1;
    while (snd_card_next(&card) == 0 && card >= 0) {
        char hw[16];
        snd_ctl_t *ctl;
        snprintf(hw, sizeof hw, "hw:%d", card);
        if (snd_ctl_open(&ctl, hw, 0) < 0)
            continue;
        int dev = -1;
        while (snd_ctl_rawmidi_next_device(ctl, &dev) == 0 && dev >= 0)
            printf("  rawmidi hw:%d,%d\n", card, dev);
        snd_ctl_close(ctl);
    }
}

int main(void)
{
    printf("\naz0x-firmware-kit: hello app is running.\n");
    printf("Sound cards:\n");
    list_cards();
    printf("MIDI ports:\n");
    list_rawmidi();
    fflush(stdout);
    for (;;)
        pause();
}
