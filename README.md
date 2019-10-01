# Waste management app

This is the waste management app, and is a part of our solution for Hospital waste management in the Singapore-India hackathon 2019.

# What is it, and a demo clip

This repository houses the main app, which can control/simulate the actions of the 3 parties involved while handling our "Smart bin" during the waste disposal chain: 
* The hospital manager/representative
* The transporter
* The facility manager at the waste disposal site
>insert main app demo clip

Additionaly, it contains 3 other apps, for each of these personas to use.
> insert 3 apps demo clip

You can also generate pdf reports about the bin status.

Bin data is uploaded to firebase for use by our hospital inventory management system.

> ⚠️**WARNING**: The maps api key in this repo has been disabled. Add your own API key in `android\app\src\main\AndroidManifest.xml` for google maps to work.