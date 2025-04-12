#!/usr/bin/env python
from datetime import datetime, timedelta
import pandas as pd

def main():
    # the marathon is supposed to happen on Sunday
    marathon_week_monday =  datetime.strptime('2024-12-23', '%Y-%m-%d')

    infile = open("half_interm2_sched.html")
    df = pd.read_html(infile)[0]  # we get one dtaframe for each table
    # get rid of the first column (the week number)
    df.drop(df.columns[0], axis=1, inplace=True)
    # get rid of junk special character
    df = df.map(lambda x: x.replace('\xa0', '') if isinstance(x, str) else x)
    weeks =  df.values.tolist()

    outfile = open("goog.csv", "w")
    # https://support.google.com/calendar/answer/37118?hl=en&co=GENIE.Platform=Desktop#zippy=%2Ccreate-or-edit-a-csv-file
    print(f"Subject,Start date", file=outfile)
    week_starts = marathon_week_monday
    while weeks:
        weekly_runs = weeks.pop()
        if len(weekly_runs) != 7:
            print("the length of t weekly sche is not == 7:", weekly_runs)
            exit()
        for day, daily_run in enumerate(weekly_runs):
            datestr = (week_starts+timedelta(days=day)).strftime('%m/%d/%Y')
            print(f"{daily_run.replace('_', ' ')},{datestr}", file=outfile)
        week_starts -=  timedelta(days=7)
    outfile.close()

######################
if __name__ == "__main__":
    main()
