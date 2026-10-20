Partner Brita Armor B42.21 Compatibility v1.0.0

대상:
- Workshop 3780298456
- Mod ID BritasArmorPackB42
- 확인한 버전 1.4.9
- Project Zomboid 42.21

기능:
BritasArmorPackB42Fix.lua의 자체 검증 과정에서 InventoryContainer가 getFullName을 제공하지 않을 때 발생하는
"Object tried to call nil in verifyValue" 오류를 안전한 이름 조회로 우회합니다.

순서:
PartnerBritaArmorB42Compat를 BritasArmorPackB42 바로 앞에 배치해야 합니다.
이 모드는 원본 창작마당 파일을 수정하지 않습니다.

주의:
브리타 방어구팩이 업데이트되면 원본 파일의 SHA-256과 로그를 다시 확인해야 합니다.
검증 기준 원본 SHA-256:
1A6A8F6F1BB2865225DD60FE347F79A244950EECAF9CCA6F11A60E867CD3E2B3

