# ios-driving-assitant app#

**Title** : Driving Assistant

**Summary** :
iOS app that allows for your iPhone to be mounted as a dash cam and serve as a driving assistant that serves the following functions :
- Warns the driver if the car is drifting into adjacent lanes
- Issues alerts if the vehicle is not maintaining appropriate distance from the vehicles in front
- Issues a braking alert if the app predicts an impending collision


**Background** : 
- The app takes advantage of the 240fps high speed cameras that the new range of iOS devices come equipped with.
- The following features require certain speedups to operate at 240fps:
  - Lane detection : Will require using fast cascade filters for initial detection and then BRIEF based Lukas Kanade algorithm for tracking. This mode is only activated when the data from GPS indicates that the vehicle is moving at a high speed, such as on highways.
  - Distance to vehicle(in front) warnings : Requires use of a car detector to provide an initial template for BRIEF based tracking. An approximate guess of the dimensions of the vehicle in front will need to be made in order to estimate the distance to it.

**Challenges**:

- The meat of the idea relies on implementing Lukas Kanade tracking algorithm at exteremely high frame rates.
- To add to the challenge, the app must run real time on the mobile device.
- To achieve these goals, the app must use highly efficient feauture descriptors to run Lukas Kanade on.
- In order to predict impending collisions, the app must use GPS data to calculate the current speed of the vehicle and use it in a collision simulation model that takes the vehicle speed and distance from the vehicle in front as input and calculates the probability of an impending head-on collision.
