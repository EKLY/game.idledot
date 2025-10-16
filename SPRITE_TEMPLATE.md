# Sprite Template Guide - วิธีวาดรูปให้ถูกต้อง

## ภาพรวมระบบ

```
        Terrain Sprite          Building Sprite
        (256x128 px)            (256x256 px)

   ┌─────────────────┐         ┌─────────────────┐
   │                 │         │                 │ y=0 (top)
   │                 │         │      ____       │
   │                 │         │     |MINE|      │
   │                 │         │     |    |      │ <- อาคารสูงขึ้นมา
  /│\  GRASS       /│\         │    /‾‾‾‾‾‾\     │
 ───────────────────           │   /        \    │
   │                 │         │  │          │   │ y=128 (terrain ground level)
   └─────────────────┘         └─────────────────┘ y=256 (bottom)
                                        ↑
                                 ฐานอาคารชิดขอบล่าง
```

---

## 1. Terrain Sprite (พื้น)

### ข้อกำหนด:
- **ขนาด**: 256 x 128 px
- **Format**: PNG with transparency
- **จุดศูนย์กลาง**: Center (128, 64)

### วิธีวาด:
```
Canvas 256x128:
┌─────────────────────────────┐ y=0
│         /‾‾‾‾‾‾‾\           │
│        /         \          │
│       /   GRASS   \         │
│      |             |        │
│       \           /         │
│        \_________/          │
└─────────────────────────────┘ y=128
```

### Checklist:
- ☐ ขนาดพอดี 256x128 px
- ☐ Hexagon shape (flat-top)
- ☐ พื้นหลังโปร่งใส
- ☐ ศูนย์กลางอยู่ตรงกลาง canvas

---

## 2. Building Sprite (อาคาร)

### ข้อกำหนด:
- **ขนาด**: 256 x 256 px (สี่เหลี่ยมจัตุรัส)
- **Format**: PNG with transparency
- **จุดยึด**: Bottom-center (128, 256)
- **สำคัญ**: ฐานอาคารต้องชิดขอบล่างของ canvas!

### วิธีวาด (Layer Breakdown):

```
Canvas 256x256 (Building):

┌─────────────────────────────┐ y=0   [ครึ่งบน - โผล่ขึ้นมา]
│                             │
│          ______             │ y=50  <- ยอดอาคาร
│         |      |            │
│         | MINE |            │ y=100 <- ตัวอาคาร (ส่วนบน)
│         |      |            │
│ - - - - - - - - - - - - - - │ y=128 <- **เส้นพื้น terrain**
│        /|‾‾‾‾‾‾|            │ y=150 [ครึ่งล่าง - ซ้อน terrain]
│       / |      |            │
│      /  | BASE |            │ y=200 <- ฐานอาคาร (ซ้อนกับ terrain)
│     │   |______|            │ y=220
│      \          \           │ y=240
│       \__________\          │ y=256 <- **ชิดขอบล่าง**
└─────────────────────────────┘
         ^                          ↑
         x=128 (center)              ซ้อนกับ terrain ด้านล่าง

Terrain Layer (256x128) - อยู่ใต้ building:
┌─────────────────────────────┐ y=0
│        /‾‾‾‾‾‾‾‾\           │
│       /          \          │
│      │   GRASS   │          │ <- terrain (ถูกซ้อนด้วย building)
│       \          /          │
│        \________/           │ y=128
└─────────────────────────────┘
```

**สำคัญ**:
- เส้น y=128 คือจุดที่ building เริ่มซ้อนกับ terrain
- ครึ่งบน (y=0-128): โผล่ขึ้นเหนือ tile
- ครึ่งล่าง (y=128-256): ซ้อนทับ terrain layer

### Checklist:
- ☐ ขนาดพอดี 256x256 px (สี่เหลี่ยมจัตุรัส)
- ☐ ฐานอาคาร**ชิดขอบล่าง** (y=256)
- ☐ ศูนย์กลาง x=128
- ☐ พื้นหลัง**โปร่งใส 100%**
- ☐ อาคารวาดจากล่างขึ้นบน
- ☐ ส่วนบนโผล่ขึ้นมาเหนือ terrain

---

## 3. ตัวอย่างการจัดวางในเกม

```
ในเกม (หลังจาก scale):

     Building (120x120)
     ┌─────────┐ <- ครึ่งบนโผล่ขึ้น (60px)
     │  ____   │
     │ |MINE|  │ <- โผล่เหนือ terrain
     │ |    |  │
- - -│/|‾‾‾‾|\│- - - <- เส้นพื้น terrain (y=0)
    /│ |____| │\
   / └─────────┘ \  <- ครึ่งล่างซ้อนกับ terrain (60px)
  │   TERRAIN    │  <- Terrain (120x60) อยู่ใต้
   \            /
    \__________/

สังเกต:
- Building ครึ่งบน (60px) อยู่เหนือ terrain
- Building ครึ่งล่าง (60px) ซ้อนทับ terrain
- Bottom ของทั้งสองชิดกัน
```

---

## 4. เคล็ดลับการวาด

### สำหรับ Terrain:
1. วาด hexagon outline ก่อน
2. เติมสี texture (หญ้า, หิน, น้ำ)
3. เพิ่ม shadow/highlight เล็กน้อย
4. ลบ background layer

### สำหรับ Building:
1. **เริ่มจากด้านล่าง** (y=256) วาดฐานก่อน
2. วาดตัวอาคารค่อยๆ สูงขึ้น
3. เพิ่มรายละเอียด (หน้าต่าง, ประตู)
4. เพิ่ม shadow ด้านล่าง
5. ตรวจสอบว่า**ฐานชิดขอบล่าง**
6. ลบ background layer

---

## 5. เทมเพลต Photoshop/GIMP

### Terrain Template (256x128):
```
Layers:
- Guide Lines (hide before export)
  - Horizontal: y=64 (center)
  - Vertical: x=128 (center)
- Terrain Drawing
- Background (DELETE)
```

### Building Template (256x256):
```
Layers:
- Guide Lines (hide before export)
  - Horizontal: y=128 (terrain ground level)
  - Horizontal: y=256 (building base - ALIGN HERE!)
  - Vertical: x=128 (center)
- Building Top (y=0-128)
- Building Base (y=128-256)
- Background (DELETE)
```

---

## 6. การทดสอบ

### Test Checklist:
1. ☐ วาง sprite ในโฟลเดอร์ `assets/sprites/`
2. ☐ ตั้งชื่อถูกต้อง (`terrain_*.png` หรือ `building_*.png`)
3. ☐ Run เกม
4. ☐ ตรวจสอบว่า:
   - Terrain แสดงครบทุก tile
   - Building ฐานชิดกับพื้น terrain
   - Building ไม่ลอยหรือจมใต้พื้น
   - ขนาดพอดี ไม่เล็กหรือใหญ่เกินไป

---

## 7. ตัวอย่างค่า Y สำหรับอาคารแต่ละประเภท

```
Building Type    | Base Y | Height | Top Y
-----------------|--------|--------|-------
Small (Farm)     | 256    | 100    | 156
Medium (Mine)    | 256    | 140    | 116
Tall (Factory)   | 256    | 180    | 76
Tower            | 256    | 220    | 36
```

---

## 8. Common Mistakes (ข้อผิดพลาดที่พบบ่อย)

❌ **ผิด**: อาคารอยู่ตรงกลาง canvas (y=128 center)
```
┌─────────┐
│         │ <- ว่างเกินไป
│  MINE   │ <- ตรงกลาง (ผิด!)
│         │ <- ว่างเกินไป
└─────────┘
```

✅ **ถูก**: อาคารชิดด้านล่าง (y=256 bottom)
```
┌─────────┐
│         │ <- โผล่ขึ้นมา
│  MINE   │
│  BASE   │ <- ชิดล่าง (ถูก!)
└─────────┘
```

---

## 9. Export Settings

### Photoshop:
- File → Export → Export As
- Format: PNG
- Transparency: ✓ Checked
- Size: 100%

### GIMP:
- File → Export As
- Select PNG
- Compression level: 9
- Save background color: ✗ Unchecked

### Aseprite:
- File → Export
- Format: PNG
- Resize: 100%
- Apply pixel perfect: ✓ Checked

---

สนุกกับการวาด sprite! 🎨
