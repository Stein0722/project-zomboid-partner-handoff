# Viewpoint + 탄도 호환 최신 인계

기준일은 2026-10-25이며 게임은 Project Zomboid Build 42.21입니다.

## 본 세이브 상태

활성:

- `Viewpoint` 0.1.6.1
- `ProjectViewpointQOL`
- `PZVoxelStudioViewpoint` 1.0
- `PartnerLightweightBallistics` 1.3.1-test-bridge

비활성:

- `ViewpointTrueBallistics`
- `PartnerViewpointBallisticsBridge`
- `ProjectViewpointADS`
- `ViewpointAdvancedThrowables`
- VSGirl의 Viewpoint 전용 바디 변형

3인칭 휠 줌과 기본 전투는 인게임에서 정상 동작했습니다. QOL 로그의 `viewpoint.input.ThirdPerson` 클래스 탐색 실패는 남지만, 카메라 줌 초기화와 실제 줌이 정상이라 현재는 기능을 막지 않는 구형 보조 후킹 경고로 판단합니다. 원본 Viewpoint/QOL JAR는 수정하지 않습니다.

## 탄도 브리지 시험 상태

`PartnerViewpointBallisticsBridge` v0.1.0은 복제 세이브 `2026-10-17_07-34-08_PartnerTest_20261024`에서만 활성화했습니다.

- 쿼터뷰: Partner Lightweight Ballistics가 탄도 소유
- 1·3인칭: Viewpoint True Ballistics가 탄도 소유
- `VTB.UseInIsoView=false`, `VTB.Enabled=true`
- 시점은 10 게임 틱마다 확인하고 공격 직전에 다시 확인
- 시점이 바뀔 때 현재 손에 든 무기만 조정
- PLB 산탄 추가 관통과 Mastery 총기 과잉관통은 VTB 소유 중 정지

자동 모의 시험에서는 시점 왕복 30회 수치 드리프트, 중복 관통, VTB 미로딩 폴백, 샷건 정지·복귀를 통과했습니다. 실제 로그에서는 `camera=isometric owner=PartnerLightweightBallistics` 뒤 `camera=third owner=TrueBallistics` 전환과 VTB 발사 후킹을 확인했습니다. 사용자는 시점별 전투에 이상이 없다고 확인했지만, 부착물 총기와 대규모 전투의 장시간 검증은 아직 남아 있습니다.

## 남은 주의점

- 부착물이 있는 총은 다른 모드가 바꾼 능력치를 지우지 않기 위해 일부 원복을 건너뜁니다.
- Viewpoint 설정은 아직 400 FPS를 요청하지만 게임 옵션 상한은 244이고 PZ Optimization 별도 상한은 330입니다. 이것은 코드 패치가 아니라 설정 정리 항목입니다.
- QOL의 기본 `K` 키는 사용자가 보는 FPS 표시 키와 겹칠 수 있습니다.
- 최신 시험 로그에는 Mastery, PLB, Legend의 `%` 문구 관련 번역 경고가 남아 있습니다. 전투 로직 오류와는 별개지만 다음 번역 정리 때 수정해야 합니다.
- 본 세이브에 VTB와 브리지를 넣기 전에는 복제 세이브에서 부착물 없는 권총, 부착물 총기, 소총, 산탄총을 쿼터뷰↔1인칭↔3인칭으로 반복 시험합니다.

## 안전 경계

- Workshop 원본 파일을 복사·수정·재배포하지 않습니다.
- 브리지는 공개 Lua/Java 상태 API만 읽고 우리가 만든 PLB·Mastery 코드만 전환합니다.
- 본 세이브 활성화는 별도 백업과 사용자의 명시적 요청 뒤에만 진행합니다.
