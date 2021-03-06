//
//  InputController.swift
//  MetalGameEngine
//
//  Created by 최승민 on 2021/12/05.
//

import Cocoa

protocol KeyboardDelegate
{
    func keyPressed(key: KeyboardControl, state: InputState) -> Bool
}

protocol MouseDelegate
{
    func mouseEvent(mouse: MouseControl, state: InputState,
                  delta: float3, location: float2)
}

class InputController
{
    var keyboardDelegate: KeyboardDelegate?
    var directionKeysDown: Set<KeyboardControl> = []

    var player: Node?
    var translationSpeed: Float = 2.0
    var rotationSpeed: Float = 1.0

    var mouseDelegate: MouseDelegate?
    var useMouse = false

    public func updatePlayer(deltaTime: Float)
    {
        guard let player = player else { return }
        let translationSpeed = deltaTime * self.translationSpeed
        let rotationSpeed = deltaTime * self.rotationSpeed
        var direction: float3 = [0, 0, 0]
        for key in directionKeysDown
        {
            switch key
            {
                case .w:
                    direction.z += 1
                case .a:
                    direction.x -= 1
                case.s:
                    direction.z -= 1
                case .d:
                    direction.x += 1
                case .left, .q:
                    player.rotation.y -= rotationSpeed
                case .right, .e:
                    player.rotation.y += rotationSpeed
                default:
                    break
            }
        }
        if direction != [0, 0, 0]
        {
            direction = normalize(direction)
            player.position += (direction.z * player.forwardVector + direction.x * player.rightVector) * translationSpeed
        }
    }

    func processEvent(key inKey: KeyboardControl, state: InputState)
    {
        let key = inKey
        if !(keyboardDelegate?.keyPressed(key: key, state: state) ?? true)
        {
            return
        }
        if state == .began
        {
            directionKeysDown.insert(key)
        }
        if state == .ended
        {
            directionKeysDown.remove(key)
        }
    }

    func processEvent(mouse: MouseControl, state: InputState, event: NSEvent)
    {
        let delta: float3 = [Float(event.deltaX), Float(event.deltaY), Float(event.deltaZ)]
        let locationInWindow: float2 = [Float(event.locationInWindow.x), Float(event.locationInWindow.y)]
        mouseDelegate?.mouseEvent(mouse: mouse, state: state, delta: delta, location: locationInWindow)
    }
}

enum InputState
{
    case began, moved, ended, cancelled, continued
}

enum KeyboardControl: UInt16
{
    case a =      0
    case d =      2
    case w =      13
    case s =      1
    case down =   125
    case up =     126
    case right =  124
    case left =   123
    case q =      12
    case e =      14
    case key1 =   18
    case key2 =   19
    case key0 =   29
    case space =  49
    case c =      8
}

enum MouseControl
{
    case leftDown, leftUp, leftDrag, rightDown, rightUp, rightDrag, scroll, mouseMoved
}
