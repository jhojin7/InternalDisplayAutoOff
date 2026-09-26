#ifndef SystemControlsShim_h
#define SystemControlsShim_h

#include <stdbool.h>

bool MTBColorFilterIsAvailable(void);
bool MTBColorFilterIsEnabled(void);
bool MTBSetColorFilterEnabled(bool enabled);

bool MTBNightShiftIsAvailable(void);
bool MTBNightShiftIsActive(void);
bool MTBSetNightShiftEnabled(bool enabled);
bool MTBStartNightShiftStatusNotifications(void);

#endif
