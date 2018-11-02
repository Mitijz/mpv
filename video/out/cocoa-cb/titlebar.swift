/*
 * This file is part of mpv.
 *
 * mpv is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * mpv is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with mpv.  If not, see <http://www.gnu.org/licenses/>.
 */

import Cocoa

class TitleBar: NSVisualEffectView {

    weak var cocoaCB: CocoaCB! = nil

    var bar: NSView {
        get { return (window!.standardWindowButton(.closeButton)?.superview)! }
    }
    static var height: CGFloat {
        get { return NSWindow.frameRect(forContentRect: CGRect.zero, styleMask: .titled).size.height }
    }
    var buttons: [NSButton] {
        get { return ([.closeButton, .miniaturizeButton, .zoomButton] as [NSWindowButton]).flatMap { window!.standardWindowButton($0) } }
    }

    override var material: NSVisualEffectView.Material {
        get { return super.material }
        set {
            super.material = newValue
            /*if material == .light || material == .dark || material == .mediumLight || material == .ultraDark {
                Swift.print("---set material is broken")
            }*/

        }
    }

    convenience init(frame frameRect: NSRect, cocoaCB ccb: CocoaCB) {
        let f = NSMakeRect(0, frameRect.size.height - TitleBar.height,
                           frameRect.size.width, TitleBar.height)
        self.init(frame: f)
        cocoaCB = ccb
        alphaValue = 0
        blendingMode = .withinWindow
        autoresizingMask = [.viewWidthSizable, .viewMinYMargin]

        //titleBarEffect!.wantsLayer = true
        //titleBarEffect!.layer?.backgroundColor = NSColor.clear.cgColor
    }

    // catch these events so they are not propagated to the underlying view
    override func mouseDown(with event: NSEvent) { }

    override func mouseUp(with event: NSEvent) {
        if event.clickCount > 1 {
            let def = UserDefaults.standard
            var action = def.string(forKey: "AppleActionOnDoubleClick")

            // macOS 10.10 and earlier
            if action == nil {
                action = def.bool(forKey: "AppleMiniaturizeOnDoubleClick") == true ?
                    "Minimize" : "Maximize"
            }

            if action == "Minimize" {
                window!.miniaturize(self)
            } else if action == "Maximize" {
                window!.zoom(self)
            }
        }
    }

    func appearanceFromString(_ ap: String) -> NSAppearance? {
        switch ap {
        case "1", "aqua":
            return NSAppearance(named: NSAppearanceNameAqua)
        case "3", "vibrantLight":
            return NSAppearance(named: NSAppearanceNameVibrantLight)
        case "4", "vibrantDark":
            return NSAppearance(named: NSAppearanceNameVibrantDark)
        default: break
        }

        if #available(macOS 10.14, *) {
            switch ap {
            case "2", "darkAqua":
                return NSAppearance(named: NSAppearanceNameDarkAqua)
            case "5", "aquaHighContrast":
                return NSAppearance(named: NSAppearanceNameAccessibilityHighContrastAqua)
            case "6", "darkAquaHighContrast":
                return NSAppearance(named: NSAppearanceNameAccessibilityHighContrastDarkAqua)
            case "7", "vibrantLightHighContrast":
                return NSAppearance(named: NSAppearanceNameAccessibilityHighContrastVibrantLight)
            case "8", "vibrantDarkHighContrast":
                return NSAppearance(named: NSAppearanceNameAccessibilityHighContrastVibrantDark)
            case "0", "auto": fallthrough
            default:
                return nil
            }
        }

        let style = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
        return appearanceFromString(style == nil ? "aqua" : "vibrantDark")
    }

    func materialFromString(_ mat: String) -> NSVisualEffectView.Material {
        switch mat {
        case "1",  "selection":	return .selection
        case "0",  "titlebar":	return .titlebar
        case "14", "dark":	    return .dark
        case "15", "light":	    return .light
        default:                break
        }

        if #available(macOS 10.11, *) {
            switch mat {
            case "2,", "menu":	        return .menu
            case "3",  "popover":	    return .popover
            case "4",  "sidebar":	    return .sidebar
            case "16", "mediumLight":	return .mediumLight
            case "17", "ultraDark":	    return .ultraDark
            default:                    break
            }
        }

        if #available(macOS 10.14, *) {
            switch mat {
            case "5,", "headerView":	        return .headerView
            case "6",  "sheet":	                return .sheet
            case "7",  "windowBackground":	    return .windowBackground
            case "8",  "hudWindow":	            return .hudWindow
            case "9",  "fullScreen":	        return .fullScreenUI
            case "10", "toolTip":	            return .toolTip
            case "11", "contentBackground":	    return .contentBackground
            case "12", "underWindowBackground": return .underWindowBackground
            case "13", "underPageBackground":	return .underPageBackground
            default:                            break
            }
        }

        return .titlebar
    }

    func setTitelAppearance(_ titelAp: Any) {
        var ap: String

        if titelAp is Int {
            ap = String(titelAp as! Int)
        } else {
            ap = titelAp as! String
        }

        window!.appearance = appearanceFromString(ap)
        Swift.print(window!.appearance?.name)
    }

    func setMaterial2(_ titelMat: Any) {
        var mat: String

        if titelMat is Int {
            mat = String(titelMat as! Int)
        } else {
            mat = titelMat as! String
        }

        material = materialFromString(mat)
        //titleBarEffect!.state = .followsWindowActiveState

        Swift.print("---")
        Swift.print(material.rawValue)
        Swift.print(state.rawValue)
        state = .followsWindowActiveState
        Swift.print(state.rawValue)
        Swift.print("---")
    }

    func show() {
        if (!cocoaCB.window.border && !cocoaCB.window.isInFullscreen) { return }
        let loc = cocoaCB.view.convert(cocoaCB.window.mouseLocationOutsideOfEventStream, from: nil)

        buttons.forEach { $0.isHidden = false }
        NSAnimationContext.runAnimationGroup({ (context) -> Void in
            context.duration = 0.20
            bar.animator().alphaValue = 1
            if !cocoaCB.window.isInFullscreen && !cocoaCB.window.isAnimating {
                animator().alphaValue = 1
                isHidden = false
            }
        }, completionHandler: nil )

        if loc.y > TitleBar.height {
            hideDelayed()
        } else {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(hide), object: nil)
        }
    }

    func hide() {
        if cocoaCB.window.isInFullscreen && !cocoaCB.window.isAnimating {
            alphaValue = 0
            isHidden = true
            return
        }
        NSAnimationContext.runAnimationGroup({ (context) -> Void in
            context.duration = 0.20
            bar.animator().alphaValue = 0
            animator().alphaValue = 0
        }, completionHandler: {
            self.buttons.forEach { $0.isHidden = true }
            self.isHidden = true
        })
    }

    func hideDelayed() {
        NSObject.cancelPreviousPerformRequests(withTarget: self,
                                                 selector: #selector(hide),
                                                   object: nil)
        perform(#selector(hide), with: nil, afterDelay: 0.5)
    }
}