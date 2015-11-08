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

**Goals and Deliverables**:

- Plan to achieve to build an app that is able to reasonably estimate the distance to the vehicle in front and make suggestion to the driver to slow down if necessary. The app needs to run real time, at a decently high camera resolution and frame rate to track vehicles at high speeds.
- In case I do achieve the above goal before the December 11 deadline, then I hope to add a lane and stop sign detection feature to the appas well.
- Also, over the winter break, I hope to collaborate with hardware-specialists to build a device that plugs into the OBD port found in all cars to transmit the state of the car (speed, braking force, etc.) directly from the car's ECU to the app in order to improve the quality of collision predictions.
- Through this app, I hope to make a driving assistant that reduces the probability of road accidents.

**Schedule**:
<style type="text/css">
.tg  {border-collapse:collapse;border-spacing:0;}
.tg td{font-family:Arial, sans-serif;font-size:14px;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;}
.tg th{font-family:Arial, sans-serif;font-size:14px;font-weight:normal;padding:10px 5px;border-style:solid;border-width:1px;overflow:hidden;word-break:normal;}
.tg .tg-yw4l{vertical-align:top}
</style>
<table class="tg">
  <tr>
    <th class="tg-yw4l">Week Ending</th>
    <th class="tg-yw4l">Action item</th>
  </tr>
  <tr>
    <td class="tg-yw4l">Nov 14</td>
    <td class="tg-yw4l">Write code to implement object tracking for vehicles in front</td>
  </tr>
  <tr>
    <td class="tg-yw4l">Nov 21</td>
    <td class="tg-yw4l">Refine object tracking code to run faster</td>
  </tr>
  <tr>
    <td class="tg-yw4l">Nov 28</td>
    <td class="tg-yw4l">Write code for car detector to provide template to object tracker</td>
  </tr>
  <tr>
    <td class="tg-yw4l">Dec 5</td>
    <td class="tg-yw4l">Iron out bugs and integrate tracker and detector</td>
  </tr>
  <tr>
    <td class="tg-yw4l">Dec 11</td>
    <td class="tg-yw4l">UI/UX design</td>
  </tr>
</table>
