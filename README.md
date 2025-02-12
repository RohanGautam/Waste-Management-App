# Waste management app, Singapore India Hackathon 2019

This is a waste management app for hospitals, and is a part of our solution for Hospital waste management in the Singapore-India hackathon 2019.

# What is it, and a demo clip

This repository houses the main app, which can control/simulate the actions of the 3 parties involved while handling our "Smart bin" during the waste disposal chain: 
* The hospital manager/representative
* The transporter
* The facility manager at the waste disposal site

## Features
* Secure transportation system
* 2-Party Authentication to Lock/Unlock - Immediate authority transfer
* Only Lock/Unlock at valid Geo-Fence
* Upload all transactions to append-only database
* Measure volume/weight at hospital and facility

### Main app demo
[![Smart bin demo main app](https://i.ibb.co/tq0c9QL/https-i-ytimg-com-vi-PNRIRpe3y1-Y-hqdefault.jpg)](https://youtu.be/PNRIRpe3y1Y "Smart bin demo main app")

### Demo of the 3 apps for 3 personas
Additionaly, it contains 3 other apps, for each of these personas to use.
[![Smart bin demo , 3 apps for 3 personas](https://i.ibb.co/t2J34G7/https-i-ytimg-com-vi-o-Jr-Vj-V9s6l-Y-hqdefault.jpg)](https://youtu.be/oJrVjV9s6lY "Smart bin demo , 3 apps for 3 personas")

You can also generate pdf reports about the bin status.

Bin data is uploaded to firebase for use by our hospital inventory management system.

> ⚠️**WARNING**: The maps api key in this repo has been disabled. Add your own API key in `android\app\src\main\AndroidManifest.xml` for google maps to work.

# Other parts of this project
* Repository for website is [here.](https://github.com/txtr/nautic)
* Repository for Hardware and computer vision is [here.](https://github.com/laksh22/SIH-Team19)
