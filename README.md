# Coomunication Protocols

## Interfaces Classification
---
### Simplex vs Duplex

**Simplex** : Data can only travel from sender to receiver (in one direction).

**Duplex** : Data can travel from device1 to device2 and vice versa.
 - Half-Duplex : At one time only one device can communicate the data.
 - Full-Duplex : Both devices can simultaneously send or receive data.

---
### Serial vs Parallel

**Serial** : Data sent serially on line. e.g. UART
**Parallel** : Data sent parallelly on line.

---
### Synchronous vs Asynchronous

**Synchronous** : Both sender and receiver share common clock (SPI, I2C).
- Device that sends clock: **Master**
- Device that receives clock: **Slave**

**Asynchronous** : Data is sent without a clock (UART).

---
### Point-to-point vs Multi-drop vs Multi-point

**Point-to-point** : Communication between two devices *(UART)*.

**Multi-drop** : Single transmitter and multiple receivers *(SPI)*.

**Multi-point** : Channel is shared between devices *(I2C)*.
