//
//  CalendarDay.m
//  DayimaCalendarDay
//
//  Created by lt on 14/12/16.
//  Copyright (c) 2014年 lt. All rights reserved.
//

#import "CalendarDay.h"

extern int lib_get_today_dateline(void);
extern int lib_date_add(int date, int offset);

@implementation CalendarDay

#pragma mark - public methods

+ (NSInteger)datelineToday {
    return lib_get_today_dateline();
}

+ (NSInteger)datelineWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day {
    return [[NSString stringWithFormat:@"%04zd%02zd%02zd", year, month, day] integerValue];
}

+ (NSInteger)dateline:(NSInteger)dateline byDayOffset:(NSInteger)offset {
    return lib_date_add((int)dateline, (int)offset);
}

@end





#include <math.h>

bool is_leap_year(short year) {
    if (year % 100 == 0) {
        if (year % 400 == 0) {
            return true;
        }
    } else {
        if (year % 4 == 0) {
            return true;
        }
    }
    return false;
}

short get_year_days(short year, unsigned char month, unsigned char day) {
    unsigned char mdays[] = { 30, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
    if (is_leap_year(year)) {
        mdays[2] = 29;
    }
    short days = 0;
    unsigned char i = 1;
    for (; i < month; ++i) {
        days += mdays[i];
    }
    days += day;
    return days;
}

void swap(int *a, int *b) {
    int t = *a;
    *a = *b;
    *b = t;
}

int lib_get_today_dateline() {
    time_t t = time(NULL);
    struct tm *local = localtime(&t);
    return (local->tm_year + 1900) * 10000 + (local->tm_mon + 1) * 100 + local->tm_mday;
}

int lib_date_diff(int from, int to) {
    int factor = 1;
    int year0 = 0, year1 = 0, month0 = 0, month1 = 0, day0 = 0, day1 = 0;
    if (from == 0) {
        from = lib_get_today_dateline();
    }
    year0 = from / 10000;
    month0 = (from - year0 * 10000) / 100;
    day0 = from - year0 * 10000 - month0 * 100;
    if (to == 0) {
        to = lib_get_today_dateline();
    }
    year1 = to / 10000;
    month1 = (to - year1 * 10000) / 100;
    day1 = to - year1 * 10000 - month1 * 100;
    if (from > to) {
        factor = -1;
        swap(&from, &to);
        swap(&year0, &year1);
        swap(&month0, &month1);
        swap(&day0, &day1);
    }
    short ydays_from = get_year_days(year0, month0, day0);
    short ydays_to = get_year_days(year1, month1, day1);
    short cur = year0;
    int diff_days = 0;
    for (; cur < year1; ++cur) {
        if (is_leap_year(cur)) {
            diff_days += 366;
        } else {
            diff_days += 365;
        }
    }
    diff_days += (ydays_to - ydays_from);
    return factor * diff_days;
}

int lib_date_add(int date, int offset) {
    unsigned char mdays[] = { 30, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
    int year = date / 10000;
    int month = (date - year * 10000) / 100;
    int day = date - year * 10000 - month * 100;
    day += offset;
    if (is_leap_year(year)) {
        mdays[2] = 29;
    } else {
        mdays[2] = 28;
    }

    while (day > mdays[month]) {
        if (month < 12) {
            day -= mdays[month];
            month++;
        } else {
            year++;
            month = 1;
            day -= mdays[12];
            if (is_leap_year(year)) {
                mdays[2] = 29;
            } else {
                mdays[2] = 28;
            }
        }
    }
    while (day < 1) {
        if (month > 1) {
            month--;
            day += mdays[month];
        } else {
            year--;
            month = 12;
            day += mdays[12];
            if (is_leap_year(year)) {
                mdays[2] = 29;
            } else {
                mdays[2] = 28;
            }
        }
    }
    date = year * 10000 + month * 100 + day;
    return date;
}
