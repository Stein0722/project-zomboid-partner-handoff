# Viewpoint / True Ballistics / Partner Ballistics 호환성 검증 기록

검토 소스:
- 사용자 제공 `3809306528.zip` (Viewpoint, Viewpoint.View.next() Java API 실제 동작 확인)
- 사용자 제공 `3812864848.zip` (VTB 1.4.6, BallisticsManager.wouldSimulate 및 설정 확인)
- PartnerLightweightBallistics v1.3.0
- PartnerMasteryExtension v0.3.0

## 소유권
- Viewpoint.View.next() == first: 현재 쿼터뷰 (다음 모드 1인칭)
- Viewpoint.View.next() == third: 현재 1인칭 (다음 모드 3인칭)
- Viewpoint.View.next() == isometric: 현재 3인칭 (다음 모드 쿼터뷰)
- VTB Java가 로드되어 있고 VTB.Enabled=true이며 현재 1/3인칭이면 VTB 소유.
- `VTB.UseInIsoView=true`면 양 시스템 충돌을 피하기 위해 모든 시점에서 VTB 소유. 사용자의 의도대로 사용하려면 해당 옵션 false 유지.
- Java 미로딩 / VTB disabled: PLB 유지.

## 변경 범위
- TEST PLB: 읽기 전용 Viewpoint Bridge가 호출하는 SetExternalBallistics/RefreshBridgeWeapon API 추가. 현재 장착한 무기만 안전 복원/재적용, 카테고리 관통 오버레이 복원, 샷건 bonus hit/shot 활성화 분리.
- TEST MasteryExtension: 총기 과잉관통은 VTB 소유 중 억제. 기존 근접 스플래시/불멸 무구 보존.
- 별도 Bridge: 10 틱에 한 번 시점 체크, 총기 공격 직전 한 번 재확인, 상태 변경 시에만 현재 장착 무기 조정.
- 3자 저작물 원본 복사/수정/병합 없이 공개 API만 연동.

## 통과한 자동 검사
- Lua 파일 18개 loadfile 구문 검사.
- 실제 원본 PLB core + class penetration + shotgun 코드 + 브리지 Lua 로드 모의 실행.
- Iso -> FPS -> TPS -> Iso에서 무기 피해/명중 대상수 원복/재적용.
- 시점 왕복 30회 수치 드리프트/영구적 중복 증가 없음.
- 샷건 부가 관통 일시 정지 및 재시작.
- VTB Java 미로딩 시 PLB 폴백.
- VTB UseInIsoView=true일 때 PLB 중복 작동 차단.
- 제3자가 변경한 무기 데미지 비강제 복원.
- MasteryExtension 14/15/20 숙련 전투 기능 회귀 테스트 + VTB 3D에서 과잉관통 차단.

## 미검증 / 배포 안전 경계
- 실제 Project Zomboid 42.21 게임에서 프레임/조준원/탄환/피격/소리 테스트 아직 미실시.
- VTB Java patches live, ZombieBuddy 승인, 로드 순서 실제 검증 필요.
- 부착물 총기는 원상복구에 따른 부착물 수치 손상 방지를 최우선으로 하기 때문에 보정 해제가 일부 누락될 수 있음; 실게임 로그와 별도 검증 필요.
- 나중에 게임과 엔진이 바뀌면 Viewpoint.View.next API 변경 가능.
- 따라서 원본 세이브에는 적용 금지. 별도 복제 세이브에서 테스트 후 정식 기존 탄도 모드로 병합 판단.
