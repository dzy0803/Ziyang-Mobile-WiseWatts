
<!-- <p align="center"><img align="center" width="300" src="./assets/Logo/WiseWatts_logo.jpeg"></p> -->
<p align="center">
  <img src="./Figures/LOGO.png" alt="Home Appliance Energy Monitoring" width="500">
</p>


=========================================================================================
# Project Description: 
**WiseWatts** is a Flutter-based mobile application platform📱designed for smart house appliance🏠and energy management⚡. It combines multiple functionalities, including home environment monitoring, remote control of appliances, power budgeting, and visualised energy data analysis, with the goal of assisting users in achieving more efficient, eco-friendly, and personalized energy consumption strategies. By leveraging Firebase cloud services, IoT devices (e.g., ESP32), and real-time chart rendering, WiseWatts delivers an intelligent user experience characterized by high operability, an intuitive interface, and prompt feedback.

**It consists of four core pages**, namely the Home Page, the Environment Page, the Devices Page and the Energy Hub Page. These pages have been functionally divided based on the key requirements of smart home energy management, and they work collaboratively to jointly build a comprehensive platform with a clear structure and complementary functions.

=========================================================================================
# 1. User Persona:
To better align with the actual usage scenarios and needs of users, we have created a concrete user persona - Walter White😎(from TV play series《Breaking Bad》). He represents ordinary family users who are under pressure from energy expenses, concerned about family financial planning, and hope to optimize their living costs through intelligent means. By depicting his background, motivations, behavioral characteristics, and pain points, we can continuously align with the concerns of real users during the product design process and ensure that the solutions are both practical and emotionally resonant.

![alt text](readme/persona.png)

=========================================================================================
# 2. Paper Prototyping:
In the early stage of product design, we adopted the method of paper prototyping to initially conceive and visually express the core page structure and interaction flow of the WiseWatts application. By rapidly iterating the interface layout and user paths through hand-drawing, it not only helped to validate the design ideas at a low cost but also provided an intuitive and clear reference framework for subsequent digital prototyping and development. This stage emphasized the verification of functional logic and user operation experience, laying the foundation for user research and interface optimization.

![alt text](readme/paper_prototype.png)



=========================================================================================
# 3. Screens:
## Splash Screen (Login/Sign up Process):
The splash screen of WiseWatts is the first stop for users when they enter the application, undertaking the dual tasks of brand display and user identity guidance. This page conveys the platform's philosophy through a simple and intuitive animation and design style, while also preparing for the subsequent page loading and user authentication from Firebase Auth.
<p align="center">
 <img src="readme/splash1.gif" alt="GIF demo" width="200"/>
 <img src="readme/splash2.gif" alt="GIF demo" width="200"/>
  <img src="readme/splash3.gif" alt="GIF demo" width="200"/>
   <img src="readme/splash4.gif" alt="GIF demo" width="200"/>
</p>

---

## **3.1. 🏠Home Page**: 
The homepage screen of WiseWatts provides users with a one-stop overview for household energy management. The page features multiple key functions presented in a card-style layout, integrating map positioning, weather information, connected environment status, household appliance on/off status, and energy consumption overview to enable users to comprehensively monitor their home's energy status. Below are the specific functionalities:  

**Current Location and Home Address Map:** Utilizes the Google Maps API and on-board GPS to detect and display the user’s current location alongside their set home address on the map, enable app to remind users to turn off unnecessary household appliances when they are not at home.

**Account Balance Display:** Real-time retrieval and display of each user's account balance information stored dedicated Firestore Database, supporting subsequent balance top-up and energy bill payments.  


**Weather Information Card:** Integrates the Google Weather API to present current and forecasted weather conditions, aiding users in optimizing energy usage strategies based on external climate factors.  

**Sensor Average Value Card:** Reads the latest 60 environmental data value (lighting, temperature, humidity, and air pressure) collected by Environment Page, calculates their average values and display, aiding users in optimizing energy usage strategies based on internal connected environment factors.  

**Device Overview Card:** Displays the total number of added devices and the count of online devices, allowing navigation to the device management page for further operations.  

**Energy Overview Card:** Retrieves briefly information (stored in Firestore Database) of weekly/monthly/annually household electricity consumption and money cost, enabling users to quickly understand their energy usage while providing access to the Energy Hub Page for detailed analysis.   

**Pay Energy Bill Card:** Provide users with a convenient entry point for energy bill payment, while also supporting users' independent selection of payment cycles.

The overall design prioritizes data accessibility and information integration. All content is automatically loaded upon program startup and remains synchronized in real-time with Firebase, delivering an intuitive, clear, and user-friendly experience.  
<p align="center">
 <img src="readme/home.gif" alt="GIF demo" width="200"/>
<img src="readme/home(1).png" alt="Static preview" width="200"/>
<img src="readme/home(2).png" alt="Static preview" width="200"/>
<img src="readme/home(3).png" alt="Static preview" width="200"/>
  <img src="readme/homemap.gif" alt="GIF demo" width="200"/>
  <img src="readme/home1.gif" alt="GIF demo" width="200"/>
    <img src="readme/home2.gif" alt="GIF demo" width="200"/>
  <img src="readme/home3.gif" alt="GIF demo" width="200"/>
    <img src="readme/home4.gif" alt="GIF demo" width="200"/>
  <img src="readme/home5.gif" alt="GIF demo" width="200"/>
    <img src="readme/home6.gif" alt="GIF demo" width="200"/>
  <img src="readme/home7.gif" alt="GIF demo" width="200"/>
</p>

---
## **3.2. 🌐Environment Page**: 
The environment page of WiseWatts is a crucial module in the platform for monitoring and recording household environmental data. Additionally, WiseWatts provides users with a sensor system developed based on ESP32 to monitor environmental parameters at their home addresses, including light intensity, temperature, humidity, and air pressure. Specifically, this page includes:

**Home Address Map Display and Management:**
This page automatically locates the user registered home address on the map through Google Geocoding Service, which helps the system to identify the source place of sensor data. Although the sign up process has helped users to recorded their home addresses to Firebase, they can change and edit their home addresse in this page, all changes synchronized to the user information databse in the Firebase.

**Real-time Environmental Data Monitoring:**
The page supports the connection with multiple data acquired from dedicated sensor system in users' home, including: Illumination intensity (Lux) , Temperature (°C) , Humidity (%) , Air pressure (hPa). Each piece of data from the sensor system will be sent to the Firebase Realtime Database, then the app will pull out these data from the database, refresh them in real time and displayed in the card area of this page, enhancing users' perception of changes in their home environment, so that they can make smart decision-making to control their household appliances. 

**Historical Data Charts:**
Each sensor's data retains the most recent 60 records from last one hour and is presented in the form of line graphs, facilitating users to view trends, identify anomalies, and optimize energy usage strategies. In addition, every last 60 records for each environmental variables will be averaged and synchronously displays it on the home page. 
 

## Application scenarios: 

1. Help users determine whether to turn on or off air conditioners, humidifiers and other devices; 

2. Provide an environmental reference background for energy consumption analysis; 

3. Make energy-saving decisions in coordination with the budget and equipment control module. 

4. The design of the environment page emphasizes the visualization of data and users' intuitive perception, taking into account both real-time performance and trend analysis, to enhance users' understanding and control over their home environment.

<p align="center">
 <img src="readme/EN1.gif" alt="GIF demo" width="200"/>
 <img src="readme/EN2.gif" alt="GIF demo" width="200"/>
  <img src="readme/EN3.gif" alt="GIF demo" width="200"/>
   <img src="readme/EN4.gif" alt="GIF demo" width="200"/>
</p>

## Implementation Methods:
1. For the purpose of testing and demonstration, the current application collects light intensity data directly from the built-in light sensor of a physical device (Google Pixel 6a). This approach does not require additional hardware and can quickly verify the complete process of data collection and front-end display. However, to enhance data scalability and system independence, the subsequent version plans to migrate the light sensor to an external module developed based on the ESP32 platform and achieve data synchronization through wireless communication, thereby better supporting cross-device deployment and real-scenario simulation.
<p align="center">
 <img src="readme/light.gif" alt="GIF demo" width="400"/>
</p>

2. The temperature and humidity environmental data are collected by the DHT11 sensor connected to the ESP32 and uploaded in real time to the Firebase cloud database (Realtime Database). The mobile application dynamically displays the latest environmental status by listening to the data changes in Firebase.

<p align="center">
 <img src="readme/e21.gif" alt="GIF demo" width="250"/>
  <img src="readme/e22.gif" alt="GIF demo" width="600"/>
</p>

 (You can find the ESP32 enabled DH11 sensor implementation in “.\WiseWatts\ESP32_Devices_Code\sensors” folder. Code compatible with Adruino IDE, find "ESP32 Dev Module" Board and remember to install all necessary libraries)

 3. In the current version of the WiseWatts system, the air pressure data is generated in a simulated manner. That is, the program generates pressure values locally at regular intervals based on a certain range and random logic. This value is set within a common range in reality (such as 980 - 1020 hPa) and updated at a second-level cycle to support chart visualization and sensor average value calculation. In future versions, a pressure sensor based on ESP32 + BME280 will be connected to perceive the real indoor pressure environment, thereby enhancing the accuracy and reference value of the data. At the same time, the sensor structure will also be optimized to make the system closer to the actual deployment scenario.

  (You can find the simulated air pressure data generation method inside ".\WiseWatts\lib\screens\environment_page.dart", with the following implementation inside void _startSensorListeners() method of class _EnvironmentPageState:)
```dart
  timer = Timer.periodic(Duration(seconds: 1), (_) {
  setState(() {
    pressure = 980 + random.nextDouble() * 40;
    _updateHistory(pressureHistory, pressure);
  });
});
```
---
## **3.3. 📟Devices Page**: 
The Devices Page is the core module in the WiseWatts application for managing and controlling household appliances. This page enables users to add, view, control, and remove household appliance devices, aiming to help users manage their home energy usage more efficiently.

### Main Functions:
### 1. **Add Device**: Users can open the device addition interface by clicking the “+” button at the lower right corner of the page. The system supports two addition methods: 

<1>.Predefined device list: Select 30 common smart devices built into the system (such as refrigerators, air conditioners, washing machines, etc.). After clicking "Add", they will be automatically written to Firebase. 

<2>. Custom device registration: 

- Support pairing with ESP32 devices via Bluetooth Low Energy (BLE). 

- Or connect to the ESP32 hotspot via Wi-Fi mode and send the device name. 

After a successful operation, the device information will be automatically saved to Firebase, including fields such as ID, name, type, and status.

### 2. **Device Status Monitor**: The added devices will be displayed in card form, including:

- Icon, device name, unique ID

- Real-time online status (Online/Offline)

- User can click to enter the device detail page to operate.

### 3. **Device Control and Deletion**: On the device detail page, users can:

- Remotely one-click to switch the device's online/offline status that is synchronized and updated in Firebase.

- Devices Deletion (Supports individual deletion and one-click deletion of all devices).

### 4. **Real-time synchronization of each user device status**:
All device data is in real-time connection with Firebase Firestore, ensuring that additions, deletions, and status changes can be immediately reflected on all user ends.

<p align="center">
    <img src="readme/dev_devices.png" alt="Static preview" height="600"/>
    <img src="readme/dev_devices2.png" alt="Static preview" height="600"/>
</p>


### Application scenarios:

- Establish a smart home device network;

- Precisely control the operating status of the equipment and combine Energy Hub to analyze energy consumption.

- Lay the foundation for energy-saving management and remote control.

<p align="center">
 <img src="readme/dev1.gif" alt="GIF demo" width="200"/>
<img src="readme/dev2.gif" alt="Static preview" width="200"/>
<img src="readme/dev3.gif" alt="Static preview" width="200"/>
<img src="readme/dev4.gif" alt="Static preview" width="200"/>
  <img src="readme/dev5.gif" alt="GIF demo" width="200"/>
    <img src="readme/dev8.jpg" alt="Static preview" height="400"/>
  <img src="readme/dev6.gif" alt="GIF demo" width="200"/>
    <img src="readme/dev7.gif" alt="GIF demo" width="200"/>
</p>

## Implementation Methods:
During the current testing phase, to verify the system architecture and remote control functions, no real household appliances were directly connected. Instead, 
we use the LEDs connected with ESP32 to simulate different types of household appliances (such as smart fridge (red led), air conditioners(green led), wash machine (yellow led)).  

This approach facilitates high-frequency and low-risk testing during the development stage, ensuring the stability and reliability of logical chains such as device registration, status switching, and remote response, laying a foundation for future integration with actual loads (such as controlling real appliances through relays).

The WiseWatts app, through integration with Firebase Firestore, enables remote on/off control of ESP32 devices. Any control operation performed on each device in the app, such as toggling the online/offline status, is synchronously updated to the corresponding document field in Firebase (e.g., isOnline), and the ESP32 continuously monitors the status changes of its own device document to execute the actual physical response.

The control flow is as follows:

### 1. Device registration: 
Users register the ESP32 device to Firebase via Bluetooth or Wi-Fi to generate a unique deviceId. The app writes the basic device information (name, ID, type, etc.) to the devices collection in Firestore.


### 2. Status update: 
On the device detail page, users can switch the device status (on/off). The App will update the "isOnline" field in the corresponding device document.

### 3. ESP32 device real-time monitoring: 
The ESP32 connects to Firebase via Wi-Fi and listens to its corresponding document. When a change is detected in the "isOnline" field, it triggers a corresponding physical action, such as controlling the output level of a certain GPIO.

### Remote Control Demo:

<p align="center">
 <img src="readme/led1.gif" alt="GIF demo" width="450"/>
 <img src="readme/led2.gif" alt="GIF demo" width="450"/>
 <img src="readme/led3.gif" alt="GIF demo" width="450"/>
 <img src="readme/led4.gif" alt="GIF demo" width="450"/>
</p>

(You can go to the ".\WiseWatts\ESP32_Devices_Code" folder to find relevant implementation for ESP32 and Adruino Nano Wifi device. The "Bluetooth_device" file is used for letting the app scan and find the ESP32 board via bluetooth, the "WIFI_device" file is used for letting the app to connect the Arduino Nano Wifi board via phone Wi-Fi setting. Other files named end with different color leds are used for demonstrating the remote control of devices from the app 😀)

---

## **3.4. ⚡Energy Hub Page**: 
The Devices Page is the core module in the WiseWatts application for managing and controlling household appliances. This page enables users to add, view, control, and remove household appliance devices, aiming to help users manage their home energy usage more efficiently.

### Main Functions:
### 1. **Add Device**: Users can open the device addition interface by clicking the “+” button at the lower right corner of the page. The system supports two addition methods: 

<1>.Predefined device list: Select 30 common smart devices built into the system (such as refrigerators, air conditioners, washing machines, etc.). After clicking "Add", they will be automatically written to Firebase. 

<2>. Custom device registration: 

- Support pairing with ESP32 devices via Bluetooth Low Energy (BLE). 

- Or connect to the ESP32 hotspot via Wi-Fi mode and send the device name. 

After a successful operation, the device information will be automatically saved to Firebase, including fields such as ID, name, type, and status.

### 2. **Device Status Monitor**: The added devices will be displayed in card form, including:

- Icon, device name, unique ID

- Real-time online status (Online/Offline)

- User can click to enter the device detail page to operate.

### 3. **Device Control and Deletion**: On the device detail page, users can:

- Remotely one-click to switch the device's online/offline status that is synchronized and updated in Firebase.

- Devices Deletion (Supports individual deletion and one-click deletion of all devices).

### 4. **Real-time synchronization of each user device status**:
All device data is in real-time connection with Firebase Firestore, ensuring that additions, deletions, and status changes can be immediately reflected on all user ends.

<p align="center">
    <img src="readme/dev_devices.png" alt="Static preview" height="600"/>
    <img src="readme/dev_devices2.png" alt="Static preview" height="600"/>
</p>


### Application scenarios:

- Establish a smart home device network;

- Precisely control the operating status of the equipment and combine Energy Hub to analyze energy consumption.

- Lay the foundation for energy-saving management and remote control.

<p align="center">
 <img src="readme/dev1.gif" alt="GIF demo" width="200"/>
<img src="readme/dev2.gif" alt="Static preview" width="200"/>
<img src="readme/dev3.gif" alt="Static preview" width="200"/>
<img src="readme/dev4.gif" alt="Static preview" width="200"/>
  <img src="readme/dev5.gif" alt="GIF demo" width="200"/>
    <img src="readme/dev8.jpg" alt="Static preview" height="300"/>
  <img src="readme/dev6.gif" alt="GIF demo" width="200"/>
    <img src="readme/dev7.gif" alt="GIF demo" width="200"/>
</p>

## Implementation Methods:
During the current testing phase, to verify the system architecture and remote control functions, no real household appliances were directly connected. Instead, 
we use the LEDs connected with ESP32 to simulate different types of household appliances (such as smart fridge (red led), air conditioners(green led), wash machine (yellow led)).  

This approach facilitates high-frequency and low-risk testing during the development stage, ensuring the stability and reliability of logical chains such as device registration, status switching, and remote response, laying a foundation for future integration with actual loads (such as controlling real appliances through relays).

The WiseWatts app, through integration with Firebase Firestore, enables remote on/off control of ESP32 devices. Any control operation performed on each device in the app, such as toggling the online/offline status, is synchronously updated to the corresponding document field in Firebase (e.g., isOnline), and the ESP32 continuously monitors the status changes of its own device document to execute the actual physical response.

The control flow is as follows:

### 1. Device registration: 
Users register the ESP32 device to Firebase via Bluetooth or Wi-Fi to generate a unique deviceId. The app writes the basic device information (name, ID, type, etc.) to the devices collection in Firestore.


### 2. Status update: 
On the device detail page, users can switch the device status (on/off). The App will update the "isOnline" field in the corresponding device document.

### 3. ESP32 device real-time monitoring: 
The ESP32 connects to Firebase via Wi-Fi and listens to its corresponding document. When a change is detected in the "isOnline" field, it triggers a corresponding physical action, such as controlling the output level of a certain GPIO.

### Remote Control Demo:

<p align="center">
 <img src="readme/led1.gif" alt="GIF demo" width="410"/>
 <img src="readme/led2.gif" alt="GIF demo" width="410"/>
 <img src="readme/led3.gif" alt="GIF demo" width="410"/>
 <img src="readme/led4.gif" alt="GIF demo" width="410"/>
</p>

(You can go to the ".\WiseWatts\ESP32_Devices_Code" folder to find relevant implementation for ESP32 and Adruino Nano Wifi device. The "Bluetooth_device" file is used for letting the app scan and find the ESP32 board via bluetooth, the "WIFI_device" file is used for letting the app to connect the Arduino Nano Wifi board via phone Wi-Fi setting. Other files named end with different color leds are used for demonstrating the remote control of devices from the app 😀)



=========================================================================================

# Contact Details:
If you have any question❓or suggestion❗for WiseWatts⚡, feel free to contact me via email ucabzd3@ucl.ac.uk ! 😀

My working time is: 10:00 a.m. to 5:00 p.m. Monday - Friday.

Looking Forward to receving your feedback and Good Luck ！ 🧐

----
Ziyang Deng

MSc Systems Engineering for the Internet of Things

Department of Computer Science, UCL
