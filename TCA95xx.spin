{{
  Driver library for the TI TCA95xx series of I2C IO expanders
  Written by: Erik Johnson
}}
CON
  I2Caddr = $40 'TCA9555
' I2Caddr = $E8 'TCA9539

VAR
  WORD outputs[8], inputs[8], directions[8], inversions[8]

PUB setup(dataPinNumber, clockPinNumber, lockNumberToUse) '' 9 Stack Longs
  dataPin := ((dataPinNumber <# 31) #> 0)
  clockPin := ((clockPinNumber <# 31) #> 0)
  if((dataPin <> clockPin) and (chipver == 1))
    lockNumber := lockNumberToUse
    if(lockNumberToUse == -1)
      lockNumber := locknew
    result or= ++lockNumber

PUB start(device)
  device #>= 0
  device <#= 7
  outputs[device] := $FFFF
  inputs[device] := $FFFF
  directions[device] := $FFFF
  inversions[device] := $0000

  setLock
  write2bytes(device, $02, @outputs)
  write2bytes(device, $04, @inversions)
  write2bytes(device, $06, @directions)
  read2bytes(device, $00, @inputs)
  clearLock

PUB output(device, pin, state)
  device #>= 0
  device <#= 7
  outputs[device] := (outputs[device] & (!(1 << pin))) | (state << pin)
  directions[device] := directions[device] & (!(1 << pin))
  setLock
  write2bytes(device, $02, @outputs)
  write2bytes(device, $06, @directions)
  clearLock

PUB input(device, pin)
  device #>= 0
  device <#= 7
  setLock
  read2bytes(device, $00, @inputs)
  clearLock
  result := (inputs >> pin) & 1

PUB mode(device, pin, direction, inversion)
  device #>= 0
  device <#= 7
  directions := (directions & (!(1 << pin))) | (direction << pin)
  inversions := (inversions & (!(1 << pin))) | (inversion << pin)
  setLock
  write2bytes(device, $04, @inversions)
  write2bytes(device, $06, @directions) 
  clearLock

PUB getState(device, pin)
  device #>= 0
  device <#= 7
  if ((directions[device] >> pin) & 1) == 1
    result := (inputs[device] >> pin) & 1
  else
    result := (outputs[device] >> pin) & 1

PRI write2bytes(device, address, data)
  startDataTransfer
  transmitPacket(I2Caddr | device << 1)
  transmitPacket(address)
  transmitPacket(byte[data][device*2 + 0]) 
  transmitPacket(byte[data][device*2 + 1])
  stopDataTransfer

PRI read2bytes(device, address, data)
  startDataTransfer
  transmitPacket(I2Caddr | device << 1)
  transmitPacket(address)
  stopDataTransfer
  startDataTransfer
  transmitPacket(I2Caddr | device << 1 | $01)
  byte[data][device*2 + 0] := receivePacket(true) 
  byte[data][device*2 + 1] := receivePacket(false)
  stopDataTransfer

PRI transmitPacket(value) ' 4 Stack Longs
  value := ((!value) >< 8)                                                                                                                              
  repeat 8
    dira[dataPin] := value
    dira[clockPin] := false
    dira[clockPin] := true
    value >>= 1
                                                                                                                                                                     
  dira[dataPin] := false
  dira[clockPin] := false
  result := not(ina[dataPin])
  dira[clockPin] := true
  dira[dataPin] := true

PRI receivePacket(aknowledge) ' 4 Stack Longs
  dira[dataPin] := false
  repeat 8
    result <<= 1
    dira[clockPin] := false
    result |= ina[dataPin]
    dira[clockPin] := true

  dira[dataPin] := (not(not(aknowledge)))
  dira[clockPin] := false
  dira[clockPin] := true
  dira[dataPin] := true

PRI startDataTransfer ' 3 Stack Longs
  outa[dataPin] := false
  outa[clockPin] := false
  dira[dataPin] := true
  dira[clockPin] := true

PRI stopDataTransfer ' 3 Stack Longs
  dira[clockPin] := false
  dira[dataPin] := false

PRI setLock
  if(lockNumber)
    repeat while(lockset(lockNumber - 1))

PRI clearLock
  if(lockNumber)
    lockclr(lockNumber - 1)

DAT

dataPin                 byte 29 ' Default data pin.
clockPin                byte 28 ' Default clock pin.
lockNumber              byte 00 ' Driver lock number.