# **Drawing Library Documentation**

The Drawing library allows you to render custom 2D shapes, text, and images directly to the screen. Every drawing object inherits from a base DrawingObject class.

## **Constants**

### **Drawing.Fonts**

An enum-like table containing font index values for use with Text drawing objects.

| Font Name | Value |
| :---- | :---- |
| **UI** | 0 |
| **System** | 1 |
| **Plex** | 2 |
| **Monospace** | 3 |

**Example:**

local text \= Drawing.new("Text")  
text.Text \= "Hello, World\!"  
text.Font \= Drawing.Fonts.UI  
text.Size \= 18  
text.Position \= Vector2.new(300, 300\)  
text.Visible \= true

## **Constructors**

### **Drawing.new**

Creates a new drawing object of the specified type.

function Drawing.new(type: string): DrawingObject

**Parameters:**

* type (*string*, **required**): The type of drawing object to create.

**Available Types:**

| Type | Description |
| :---- | :---- |
| **Line** | A line between two points |
| **Text** | Rendered text |
| **Image** | An image from a URL or file |
| **Circle** | A circle shape |
| **Square** | A square shape |
| **Triangle** | A triangle shape with three vertices |
| **Quad** | A quadrilateral with four vertices |
| **Font** | A custom font initialized with data from a URL or file |

**Example:**

local circle \= Drawing.new("Circle")  
circle.Radius \= 50  
circle.Color \= Color3.fromRGB(255, 0, 0\)  
circle.Filled \= true  
circle.NumSides \= 32  
circle.Position \= Vector2.new(300, 300\)  
circle.Transparency \= 0.7  
circle.Visible \= true

task.wait(1)  
circle:Destroy()

## **DrawingObject**

All drawing objects inherit the following base properties and methods.

### **Base Properties**

**Note:** Transparency in the Drawing library is often the **opposite** of standard Roblox instances (e.g., 1 is fully opaque/visible, 0 is completely invisible).

| Property | Type | Default |
| :---- | :---- | :---- |
| **Visible** | boolean | false |
| **ZIndex** | number | 1 |
| **Transparency** | number | 1 |
| **Color** | Color3 | Color3.new(0, 0, 0\) |

### **Base Methods**

| Method | Description |
| :---- | :---- |
| Destroy(): () | Removes and completely destroys the DrawingObject. |
| Remove(): () | Alias for Destroy(). Destroys the DrawingObject. |

## **Object Types & Properties**

### **Line**

| Property | Type | Default |
| :---- | :---- | :---- |
| **From** | Vector2 | Vector2.new(0, 0\) |
| **To** | Vector2 | Vector2.new(0, 0\) |
| **Thickness** | number | 1 |

### **Text**

| Property | Type | Default | Notes |
| :---- | :---- | :---- | :---- |
| **Text** | string | "" |  |
| **Size** | number | 18 |  |
| **Center** | boolean | false |  |
| **Outline** | boolean | false |  |
| **OutlineColor** | Color3 | Color3.new(0, 0, 0\) |  |
| **Position** | Vector2 | Vector2.new(0, 0\) |  |
| **Font** | number | 0 | Uses Drawing.Fonts |
| **TextBounds** | Vector2 | *(Read Only)* | Size of rendered text |

### **Image**

| Property | Type | Default |
| :---- | :---- | :---- |
| **Data** | string | "" |
| **Size** | Vector2 | Vector2.new(0, 0\) |
| **Position** | Vector2 | Vector2.new(0, 0\) |
| **Rounding** | number | 0 |

### **Circle**

| Property | Type | Default |
| :---- | :---- | :---- |
| **Position** | Vector2 | Vector2.new(0, 0\) |
| **Radius** | number | 0 |
| **Thickness** | number | 1 |
| **Filled** | boolean | false |
| **NumSides** | number | 250 |

### **Square**

| Property | Type | Default |
| :---- | :---- | :---- |
| **Position** | Vector2 | Vector2.new(0, 0\) |
| **Size** | Vector2 | Vector2.new(0, 0\) |
| **Thickness** | number | 1 |
| **Filled** | boolean | false |

### **Triangle**

| Property | Type | Default |
| :---- | :---- | :---- |
| **PointA** | Vector2 | Vector2.new(0, 0\) |
| **PointB** | Vector2 | Vector2.new(0, 0\) |
| **PointC** | Vector2 | Vector2.new(0, 0\) |
| **Thickness** | number | 1 |
| **Filled** | boolean | false |

### **Quad**

| Property | Type | Default |
| :---- | :---- | :---- |
| **PointA** | Vector2 | Vector2.new(0, 0\) |
| **PointB** | Vector2 | Vector2.new(0, 0\) |
| **PointC** | Vector2 | Vector2.new(0, 0\) |
| **PointD** | Vector2 | Vector2.new(0, 0\) |
| **Thickness** | number | 1 |
| **Filled** | boolean | false |

### **Font**

| Property | Type | Default |
| :---- | :---- | :---- |
| **Data** | string | "" |

## **Utility Functions**

### **cleardrawcache**

Removes all rendered drawing objects from the cache and destroys them.

function cleardrawcache(): ()

**Example:**

\-- Draws 10 circles, then clears them all at once.  
for i \= 1, 10 do  
    local circle \= Drawing.new("Circle")  
    circle.Radius \= 50  
    circle.Color \= Color3.fromRGB(255, 0, 0\)  
    circle.Filled \= true  
    circle.NumSides \= 32  
    circle.Position \= Vector2.new(100 \* i, 100\)  
    circle.Transparency \= 0.7  
    circle.Visible \= true  
end

task.wait(1)  
cleardrawcache()

### **getrenderproperty**

Gets a property value from a DrawingObject.

function getrenderproperty(drawing: DrawingObject, property: string): any

**Parameters:**

* drawing (*DrawingObject*, **required**): The drawing object to retrieve the property from.  
* property (*string*, **required**): The exact name of the property to retrieve.

**Example:**

local circle \= Drawing.new("Circle")  
print("Radius:", getrenderproperty(circle, "Radius"))

### **isrenderobj**

Returns a boolean indicating whether the given object is a valid DrawingObject.

function isrenderobj(object: any): boolean

**Parameters:**

* object (*any*, **required**): The object or variable to evaluate.

**Example:**

local circle \= Drawing.new("Circle")  
local part \= Instance.new("Part")

print(isrenderobj(circle)) \-- true  
print(isrenderobj(part))   \-- false

### **setrenderproperty**

Sets a property value on a DrawingObject without using standard indexing.

function setrenderproperty(drawing: DrawingObject, property: string, value: any): ()

**Parameters:**

* drawing (*DrawingObject*, **required**): The drawing object to edit.  
* property (*string*, **required**): The name of the property to change.  
* value (*any*, **required**): The new value to assign to the property.

**Example:**

local circle \= Drawing.new("Circle")

setrenderproperty(circle, "Radius", 50\)  
setrenderproperty(circle, "Position", Vector2.new(300, 300))  
setrenderproperty(circle, "NumSides", 32\)  
setrenderproperty(circle, "Color", Color3.fromRGB(255, 0, 0))  
setrenderproperty(circle, "Transparency", 1\)  
setrenderproperty(circle, "Visible", true)  
setrenderproperty(circle, "Filled", true)  
setrenderproperty(circle, "Thickness", 2\)  
setrenderproperty(circle, "ZIndex", 1\)

task.wait(1)  
circle:Destroy()  




# SILENT AIM METHODS

- Workspace.FindPartOnRay  
- Workspace.findPartOnRay  
- WorldRoot.FindPartOnRay  
- WorldRoot.findPartOnRay  
- Workspace.FindPartOnRayWithWhitelist  
- WorldRoot.FindPartOnRayWithWhitelist  
- Workspace.FindPartOnRayWithIgnoreList  
- WorldRoot.FindPartOnRayWithIgnoreList  
- Ray.new  
- WorldRoot.Raycast  
- Mouse.Hit  
- Mouse.Target  
- Mouse.UnitRay  
- UserInputService.GetMouseLocation  
- Namecall hooks  
- shapecast functions  

---

# PSILENT METHODS

- BasePart.Velocity  
- BasePart.AssemblyLinearVelocity  
- LinearVelocity.VectorVelocity  
- LinearVelocity.MaxForce  
- ChildAdded  
- Workspace.ChildAdded  
- GetPropertyChangedSignal("Velocity")  
- GetPropertyChangedSignal("AssemblyLinearVelocity")  
- metatable.__newindex  
- hookmetamethod(__newindex)  
- FastCast.Fire  
- FastCast.new  
- FastCast.Cast  
- FastCastBehavior  
- Bullet.CFrame  
- CFrame.lookAt  
- CFrame.new  
- RemoteEvent.FireServer  
- __namecall  
- FireServer direction  
- hookfunction  
- Velocity correction  
- Projectile simulation  
- Attachment.WorldPosition  
- AlignPosition.Position  
- BodyVelocity  
- BodyForce  

---

# AIMBOT METHODS

- Camera.CFrame  
- workspace.CurrentCamera.CFrame  
- CFrame.lookAt  
- CFrame.Angles  
- CFrame.new  
- RunService.RenderStepped  
- RunService.Heartbeat  
- RunService.Stepped  
- mousemoverel  
- mousemove  
- UserInputService.GetMouseLocation  
- WorldToViewportPoint  
- WorldToScreenPoint  
- ViewportPointToRay  
- GetClosestPlayer  
- GetClosestPart  
- Character.HumanoidRootPart  
- Character.Head  
- Character.UpperTorso  
- HumanoidRootPart.Position  
- Head.Position  
- AimPart  
- FOV Check  
- Magnitude Check  
- Prediction  
- Velocity Prediction  
- Smoothing  
- TargetAim  
- Camera Manipulation  
- hookfunction  
- __namecall  
- Drawing.Circle  
- FOV Circle  

---

# ESP METHODS

- Drawing.new  
- Drawing.Line  
- Drawing.Circle  
- Drawing.Square  
- Drawing.Text  
- Drawing.Image  
- Drawing.Font  
- Drawing.Color3  
- Drawing.Thickness  
- Drawing.Transparency  
- Drawing.Visible  
- Drawing.Remove  
- WorldToViewportPoint  
- WorldToScreenPoint  
- GetBoundingBox  
- GetExtentsSize  
- CharacterAdded  
- RunService.RenderStepped  
- RunService.Heartbeat  
- Players.PlayerAdded  
- Highlight  
- Highlight.FillColor  
- Highlight.OutlineColor  
- Highlight.OutlineTransparency  
- Highlight.FillTransparency  
- BillboardGui  
- SurfaceGui  
- SurfaceGui.TextLabel  
- Box ESP  
- Tracer ESP  
- Skeleton ESP  
- Name ESP  
- Health ESP  
- Distance ESP  
- Weapon ESP  
- Chams  
- Material ESP  
- Team Check  
- Wall Check  
- GetChildren  
- FindFirstChild  
- FindFirstChildOfClass  

---

# TRIGGERBOT METHODS

- Mouse.Target  
- Mouse.Hit  
- Mouse.UnitRay  
- UserInputService.GetMouseLocation  
- Camera.ViewportPointToRay  
- Camera.ScreenPointToRay  
- WorldRoot.Raycast  
- Workspace.Raycast  
- FindPartOnRay  
- FindPartOnRayWithIgnoreList  
- FindPartOnRayWithWhitelist  
- Ray.new  
- __namecall  
- FireServer  
- mouse1click  
- mouse1press  
- mouse1release  
- VirtualInputManager.SendMouseButtonEvent  
- GetMouseTarget  
- Humanoid.Health  
- HumanoidRootPart  
- Character.Humanoid  
- Team Check  
- RunService.Heartbeat  
- RunService.RenderStepped  
- RunService.Stepped  
- Target.Parent  
- Target.Name  
- IsPlayer  


# SPEED METHODS

- Humanoid.WalkSpeed
- Humanoid.WalkSpeed =
- HumanoidRootPart.Velocity
- HumanoidRootPart.AssemblyLinearVelocity
- BasePart.Velocity
- BasePart.AssemblyLinearVelocity
- CFrame manipulation
- HumanoidRootPart.CFrame
- CFrame.new
- CFrame.lookAt
- root.CFrame + root.CFrame.LookVector
- root.CFrame + root.CFrame.RightVector
- RunService.RenderStepped
- RunService.Heartbeat
- RunService.Stepped
- MoveDirection
- Humanoid.MoveDirection
- BodyVelocity
- BodyVelocity.Velocity
- BodyVelocity.MaxForce
- BodyForce
- LinearVelocity
- LinearVelocity.VectorVelocity
- LinearVelocity.MaxForce
- LinearVelocity.Attachment0
- AlignPosition
- AlignPosition.Position
- AlignPosition.MaxForce
- AlignPosition.Responsiveness
- Attachment.WorldPosition
- Vector3.new
- Character.Humanoid
- Character.HumanoidRootPart
- GetPropertyChangedSignal("WalkSpeed")
- GetPropertyChangedSignal("AssemblyLinearVelocity")
- metatable.__newindex
- hookmetamethod(__newindex)
- hookfunction
- __namecall
- ChildAdded
- Workspace.ChildAdded
- AssemblyLinearVelocity correction
- Velocity boost loop
- Position teleport
- RootPart.Position
- RootPart.CFrame
