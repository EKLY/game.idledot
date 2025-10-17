# คู่มือการใส่รูปภาพ (Sprites) ลงในเกม

เกมนี้รองรับการใส่รูปภาพ 2 ประเภท:
1. **Terrain Sprites** - รูปพื้นหลังของ tile
2. **Building Sprites** - รูปอาคารที่สร้างบน tile

---

## 1. วิธีเพิ่มรูป Terrain (พื้นหลัง Tile)

### ตำแหน่งไฟล์:
```
assets/sprites/
# แบบเดิม (ไม่มี variation - ใช้เป็น fallback)
├── terrain_empty.png       # พื้นที่ว่าง (Gray)
├── terrain_field.png       # ทุ่งหญ้า (Green)
├── terrain_sand.png        # ทะเลทราย (Yellow)
├── terrain_water.png       # น้ำ (Blue)
├── terrain_snow.png        # หิมะ (White)
└── terrain_volcanic.png    # ลาวา/ภูเขาไฟ (Red)

# แบบใหม่ (มี 4 variations สุ่มเลือก)
├── terrain_empty-0.png     # Variation 0
├── terrain_empty-1.png     # Variation 1
├── terrain_empty-2.png     # Variation 2
├── terrain_empty-3.png     # Variation 3
├── terrain_field-0.png
├── terrain_field-1.png
├── terrain_field-2.png
├── terrain_field-3.png
├── terrain_sand-0.png
├── terrain_sand-1.png
├── terrain_sand-2.png
├── terrain_sand-3.png
├── terrain_water-0.png
├── terrain_water-1.png
├── terrain_water-2.png
├── terrain_water-3.png
├── terrain_snow-0.png
├── terrain_snow-1.png
├── terrain_snow-2.png
├── terrain_snow-3.png
├── terrain_volcanic-0.png
├── terrain_volcanic-1.png
├── terrain_volcanic-2.png
└── terrain_volcanic-3.png
```

**หมายเหตุ**:
- ระบบจะสุ่มเลือก variation (0-3) แบบอัตโนมัติตอนสร้าง tile
- ถ้าไม่มีไฟล์ variation (เช่น terrain_field-0.png) จะใช้ไฟล์เดิม (terrain_field.png) แทน
- ถ้าไม่มีทั้งคู่ จะแสดงสีพื้นฐานแทน

### ขนาดรูปภาพแนะนำ:
- **ความกว้าง**: 256 px (มาตรฐาน)
- **ความสูง**: 128 px (50% ของความกว้าง - คำนวณง่าย!)
- **รูปแบบ**: PNG with transparency
- **Style**: Flat-top hexagon หรือ isometric

### ตัวอย่างการทำรูป:
```
        /‾‾‾‾‾‾‾‾‾\
       /           \
      |   GRASS    |   <- 256px wide
       \           /
        \_________/
            ^
        128px tall (256 * 0.5 = 128)
```

### สร้างไฟล์:
1. วาดหรือหารูป hexagon
2. ขนาด: **256 x 128 px** (มาตรฐาน - ง่ายต่อการคำนวณ!)
3. บันทึกเป็น PNG พร้อม transparency
4. วางในโฟลเดอร์ `assets/sprites/`
5. ตั้งชื่อตามรูปแบบ: `terrain_[type]-[variation].png`

**ตัวอย่าง Field (ทุ่งหญ้า)**:
- `terrain_field-0.png` - หญ้าเขียวเรียบ
- `terrain_field-1.png` - หญ้ามีดอกไม้
- `terrain_field-2.png` - หญ้าสีต่างกันนิดหน่อย
- `terrain_field-3.png` - หญ้ามีกอนหิน

**ตัวอย่าง Sand (ทะเลทราย)**:
- `terrain_sand-0.png` - ทรายเรียบ
- `terrain_sand-1.png` - ทรายมีกอนหิน
- `terrain_sand-2.png` - ทรายลายคลื่น
- `terrain_sand-3.png` - ทรายมีตอไม้แห้ง

**ตัวอย่าง Snow (หิมะ)**:
- `terrain_snow-0.png` - หิมะเรียบ
- `terrain_snow-1.png` - หิมะมีรอยเท้า
- `terrain_snow-2.png` - หิมะมีน้ำแข็ง
- `terrain_snow-3.png` - หิมะมีก้อนหิน

**ตัวอย่าง Volcanic (ลาวา/ภูเขาไฟ)** 🌋:
- `terrain_volcanic-0.png` - หินลาวาแข็ง (สีแดงเข้ม)
- `terrain_volcanic-1.png` - ลาวาไหล (มีแนวส้มแดง)
- `terrain_volcanic-2.png` - ภูเขาไฟ (มีควันพุ่ง)
- `terrain_volcanic-3.png` - หินร้อน (มีรอยแตก)

**Tips**:
- สร้างแบบ base (variation 0) ก่อน
- คัดลอกไฟล์แล้วแก้สีหรือลายเล็กน้อย (เช่น หมุน, สลับสี, เพิ่มหิน/หญ้า)
- ไม่จำเป็นต้องต่างกันมาก แค่ดูไม่ซ้ำกันก็พอ

**หมายเหตุ**: ระบบจะปรับขนาดอัตโนมัติให้พอดีกับ hex tile (~120px ในเกม)

---

## 2. วิธีเพิ่มรูป Buildings (อาคาร)

### ตำแหน่งไฟล์:
```
assets/sprites/
├── building_iron_mine.png
├── building_copper_mine.png
├── building_gold_mine.png
├── building_coal_mine.png
├── building_wheat_farm.png
├── building_vegetable_farm.png
├── building_cotton_farm.png
├── building_fishing_dock.png
├── building_water_pump.png
├── building_factory.png
└── building_road.png
```

### ขนาดรูปภาพแนะนำ:
- **ความกว้าง**: 256 px (มาตรฐาน - ต้องเท่ากับ terrain)
- **ความสูง**: 256 px (มาตรฐาน - สูงเท่าตัวเอง)
- **รูปแบบ**: PNG with **transparency** (พื้นหลังโปร่งใส)
- **Style**: Isometric หรือ 3/4 view

### การจัดวาง (สำคัญ!):
- รูปจะแสดง**เหนือ terrain sprite**
- อาคารจะ**ชิดด้านล่างของ canvas** (bottom-aligned)
- ด้านล่างของรูปจะตรงกับพื้น terrain พอดี
- ส่วนบนของอาคารจะโผล่ขึ้นมาเหนือ tile

### ตัวอย่างการวาด (256x256 canvas):
```
Canvas: 256x256 px (Building Layer)
┌─────────────────┐ ← Top (y=0) **ส่วนโผล่ขึ้นมา**
│                 │
│      ____       │ <- อาคาร (y=0-128 โผล่เหนือ terrain)
│     |MINE|      │
│     |    |      │
│    /|‾‾‾‾|\     │ <- ฐานอาคาร (y=128) **เริ่มซ้อน terrain**
│   / |    | \    │ <- ซ้อนบน terrain ตรงนี้
│  │  |BASE| │   │ <- ครึ่งล่างซ้อนกับ terrain (y=128-256)
│   \ |____| /    │
└─────────────────┘ ← Bottom (y=256) **ชิดขอบ = ชิด terrain**
     ^^^^^^^^
     ↓↓↓ ซ้อนกับ ↓↓↓
┌─────────────────┐ Terrain (256x128)
│   /‾‾‾‾‾‾‾‾\    │ <- Terrain layer (ใต้ building)
│  │  GROUND  │   │
│   \________/    │
└─────────────────┘
```

### วิธีวาดอาคาร (สำคัญ!):
1. สร้าง canvas **256 x 256 px**
2. **วาดครึ่งล่าง (y=128-256)**: ฐานอาคารที่จะซ้อนกับ terrain
3. **วาดครึ่งบน (y=0-128)**: ตัวอาคารที่โผล่ขึ้นมา
4. เส้นแบ่ง y=128 คือ "พื้น terrain"
5. พื้นหลัง**โปร่งใส** (transparent)
6. บันทึกเป็น PNG

**การซ้อนกัน**:
- ครึ่งล่าง (y=128-256) = ซ้อนบน terrain
- ครึ่งบน (y=0-128) = โผล่ขึ้นเหนือ terrain

### สร้างไฟล์:
1. วาดอาคารในสไตล์ isometric
2. ขนาด: **256 x 256 px** (สี่เหลี่ยมจัตุรัส)
3. อาคาร**ชิดด้านล่าง** ของ canvas
4. บันทึกเป็น PNG พร้อม transparency
5. วางในโฟลเดอร์ `assets/sprites/`
6. ตั้งชื่อตามรูปแบบ: `building_[building_id].png`

---

## 3. Building IDs ทั้งหมด

| Building Type | building_id | File Name |
|---------------|-------------|-----------|
| Iron Mine | `iron_mine` | `building_iron_mine.png` |
| Copper Mine | `copper_mine` | `building_copper_mine.png` |
| Gold Mine | `gold_mine` | `building_gold_mine.png` |
| Coal Mine | `coal_mine` | `building_coal_mine.png` |
| Wheat Farm | `wheat_farm` | `building_wheat_farm.png` |
| Vegetable Farm | `vegetable_farm` | `building_vegetable_farm.png` |
| Cotton Farm | `cotton_farm` | `building_cotton_farm.png` |
| Fishing Dock | `fishing_dock` | `building_fishing_dock.png` |
| Water Pump | `water_pump` | `building_water_pump.png` |
| Factory | `factory` | `building_factory.png` |
| Road | `road` | `building_road.png` |

---

## 4. การทำงานของระบบ

### Terrain Sprites:
1. ระบบจะสุ่มเลือก variation (0-3) สำหรับแต่ละ tile
2. ลองโหลดไฟล์แบบมี variation ก่อน (เช่น `terrain_field-2.png`)
3. ถ้าไม่พบ → ลองโหลดแบบไม่มี variation (เช่น `terrain_field.png`)
4. ถ้าไม่มีทั้งคู่ → แสดงสีพื้นที่ (polygon)
5. เมื่อ selected/highlighted → sprite จะเปลี่ยนสี tint

**ตัวอย่างการโหลด**:
- Tile แรก: สุ่มได้ variation=2 → หา `terrain_field-2.png`
- Tile ที่สอง: สุ่มได้ variation=0 → หา `terrain_sand-0.png`
- ทำให้แผนที่มีความหลากหลายมากขึ้น!

### Building Sprites:
1. เมื่อสร้างอาคาร → โหลดรูปตาม `building_id`
2. ถ้ามีไฟล์รูป → แสดงรูป (เหนือ terrain)
3. ถ้าไม่มีไฟล์ → ซ่อน sprite (เห็นแค่ polygon)
4. เมื่อทำลายอาคาร → ซ่อน sprite

---

## 5. วิธีสร้างรูป Placeholder ง่ายๆ

### ใช้ Godot Editor:
1. เปิด Godot Editor
2. สร้าง Scene ใหม่ (Node2D)
3. เพิ่ม Polygon2D → วาด hexagon
4. เพิ่ม Label → ใส่ชื่อ terrain/building
5. Screenshot → Crop → Save เป็น PNG

### ใช้ Online Tools:
- **Hexagon Generator**: https://www.hexographer.com/
- **Pixel Art Editor**: https://www.pixilart.com/
- **Free Isometric Assets**: https://opengameart.org/

### ใช้ AI Image Generator:
Prompt ตัวอย่าง:
```
"isometric pixel art [building type] on hexagonal tile,
top-down view, simple style, transparent background"
```

---

## 6. Tips & Tricks

### สี Palette แนะนำ:
- **Empty**: Gray tones (#CCCCCC, #B0B0B0)
- **Field**: Green/Grass (#7CB342, #66BB6A)
- **Sand**: Sandy Yellow (#E6CC80, #D9B86A)
- **Water**: Blue (#4FC3F7, #29B6F6)
- **Snow**: White/Light Blue (#F5F5F5, #E3F2FD)
- **Volcanic**: Red/Orange (#D32F2F, #FF5722, #E65100) 🔥

### Style Consistency:
- ใช้สไตล์เดียวกันทุกรูป
- Pixel art หรือ vector แบบเดียวกัน
- Shadow/highlight ทิศทางเดียวกัน

### Performance:
- ใช้ขนาดพอดี (ไม่ใหญ่เกินไป)
- Compress PNG ด้วย tools เช่น TinyPNG
- ใช้ sprite atlas สำหรับรูปเยอะๆ

---

## 7. การทดสอบ

1. วางไฟล์รูปใน `assets/sprites/`
2. Run เกม
3. สร้าง tile หรืออาคาร
4. ตรวจสอบว่ารูปแสดงถูกต้อง

**หมายเหตุ**:
- ถ้ารูปไม่แสดง ตรวจสอบชื่อไฟล์ให้ตรงกับที่กำหนด
- ถ้ารูปเบลอ ตรวจสอบขนาดรูปและ import settings ใน Godot

---

## 8. ตัวอย่างโครงสร้างโฟลเดอร์สมบูรณ์

```
assets/sprites/
├── terrains/
│   ├── terrain_empty.png
│   ├── terrain_mountain.png
│   ├── terrain_farmland.png
│   └── terrain_water.png
├── buildings/
│   ├── mines/
│   │   ├── building_iron_mine.png
│   │   ├── building_copper_mine.png
│   │   ├── building_gold_mine.png
│   │   └── building_coal_mine.png
│   ├── farms/
│   │   ├── building_wheat_farm.png
│   │   ├── building_vegetable_farm.png
│   │   └── building_cotton_farm.png
│   └── factories/
│       ├── building_factory.png
│       └── building_road.png
└── icons/
    └── (UI icons)
```

---

## การเริ่มต้นอย่างง่าย

**ถ้ายังไม่มีรูป ระบบจะ:**
- แสดงสีพื้นฐาน (Polygon2D) แทน
- เกมยังเล่นได้ปกติ
- สามารถเพิ่มรูปภายหลังได้

**วิธีเพิ่มรูปทีละไฟล์:**
1. เริ่มจาก terrain 6 ไฟล์ (empty, field, sand, water, snow, volcanic)
2. ค่อยๆ เพิ่ม variations (0-3) สำหรับแต่ละ terrain
3. เพิ่มรูป building ทีละประเภท
4. ทดสอบว่าแสดงผลถูกต้อง

สนุกกับการออกแบบเกม! 🎮🎨
