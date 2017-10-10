timeData = 1505420300713/1000;
% timeData = 1320950127089.000000/1;
day2minMultiplier = 24*60*60;
assessTimeS = datenum('1970-1-1')*day2minMultiplier + timeData;
datestr(assessTimeS/day2minMultiplier)