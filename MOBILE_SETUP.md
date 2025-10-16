# Mobile Portrait Mode Setup

เกมนี้ถูกปรับให้เล่นบน mobile แบบแนวตั้ง (portrait orientation) เท่านั้น

## การตั้งค่าที่ทำไปแล้ว

### 1. Project Settings
- **Viewport Size**: 720x1280 (portrait)
- **Orientation**: Portrait only (locked)
- **Stretch Mode**: Canvas items with expand aspect
- **Touch Emulation**: เปิดใช้งาน (สามารถใช้เมาส์ทดสอบบน desktop)

### 2. UI Design
#### Top Bar
- แสดงจำนวนเงิน
- ปุ่ม Menu (≡)
- Font size: 24px

#### Bottom Sheet
- แสดงขึ้นเมื่อแตะ tile
- Animation slide up/down
- แสดงข้อมูล tile และ building
- ปุ่มควบคุมขนาดใหญ่ (50px height)
- Font sizes: 18-20px

#### Quick Info Panel
- แสดงข้อความสั้นๆ ที่กลางล่าง
- หายอัตโนมัติหลัง 2-3 วินาที

### 3. Touch Controls

#### การควบคุมกล้อง:
- **Single Touch + Drag**: เลื่อนกล้อง (pan)
- **Pinch Zoom**: ซูมเข้า/ออกด้วย 2 นิ้ว
- **Tap Tile**: เลือก tile

#### การเล่นเกม:
1. **Tap tile** เพื่อเลือกและดูข้อมูล
2. **Bottom Sheet** จะเลื่อนขึ้นมา
3. เลือกการกระทำ:
   - **Build**: สร้างอาคาร
   - **Sell Resources**: ขายทรัพยากรที่เก็บไว้
   - **Destroy**: ทำลายอาคาร
   - **Close**: ปิด panel

### 4. Hex Grid
- ขนาด: 10x14 tiles (เหมาะกับหน้าจอแนวตั้ง)
- Hex size: 60px (ใหญ่เพียงพอสำหรับการแตะ)
- Zoom range: 0.3x - 2.0x

## การทดสอบบน Desktop

เกมมี touch emulation เปิดอยู่ คุณสามารถทดสอบด้วยเมาส์:
- **Left Click**: เหมือน tap
- **Right Click + Drag**: เลื่อนกล้อง
- **Mouse Wheel**: ซูม
- **Arrow Keys**: เลื่อนกล้อง (debug)

## การ Export สำหรับ Mobile

### Android
1. ใน Godot Editor ไปที่ **Project → Export**
2. เลือก **Android** template
3. ตั้งค่า:
   - Screen Orientation: **Portrait**
   - Permissions: ตามต้องการ
4. Export APK

### iOS
1. ใน Godot Editor ไปที่ **Project → Export**
2. เลือก **iOS** template
3. ตั้งค่า:
   - Screen Orientation: **Portrait**
   - Bundle Identifier: com.yourcompany.idledot
4. Export Xcode project

## หมายเหตุสำหรับ Developer

### เพิ่ม UI Elements ใหม่
- ใช้ font size ขั้นต่ำ 16px
- Button height ขั้นต่ำ 44-50px (Apple/Google guidelines)
- Margin/Padding ขั้นต่ำ 10-15px

### Touch Target Size
- ขนาดขั้นต่ำ: 44x44px (iOS), 48x48px (Android)
- Hex tiles: 60px (เพียงพอสำหรับการแตะ)

### Performance
- ใช้ Mobile renderer
- Optimize textures สำหรับ mobile
- จำกัดจำนวน particles/effects

## ฟีเจอร์ที่ควรเพิ่มต่อ

1. **Build Menu**: เลือกประเภทอาคารที่จะสร้าง
2. **Settings Menu**: เสียง, การแจ้งเตือน
3. **Tutorial**: คำแนะนำสำหรับผู้เล่นใหม่
4. **Haptic Feedback**: สั่นเมื่อแตะ (iOS/Android)
5. **Cloud Save**: บันทึกข้อมูลบน cloud
