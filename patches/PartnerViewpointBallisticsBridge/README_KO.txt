Partner Viewpoint Ballistics Bridge v0.1.0 - 실게임 검증 전 테스트 전용.
ZIP에는 다음 세 폴더가 포함됨:
1) PartnerLightweightBallistics: v1.3.0 원본을 기반으로 전환 API가 추가된 TEST 복제 빌드
2) PartnerMasteryExtension: v0.3.0 기반으로 과잉관통 3D 사용 중지 가드가 추가된 TEST 복제 빌드
3) PartnerViewpointBallisticsBridge: 별도 자동 시점 전환 모드

필수: Viewpoint 본체, Viewpoint True Ballistics 1.4.6 + ZombieBuddy 승인, Beyond Ten 등 기존 요건.
VTB 모드 샌드박스 설정 Use in isometric view=false (기본값), Enabled=true.
설치 전 세 모드 폴더 백업. 게임 종료 뒤 TEST 복제 세이브에만 적용.
Viewpoint와 VTB 원본 JAR/Lua는 이 배포물에 포함하지 않음.

시점 판정: Viewpoint.View.next()가 되돌리는 '다음 시점'을 현재 시점으로 역변환한다.
쿼터뷰: PLB 기본 무기 보정 + 추가 샷건 후방 관통 + Mastery 과잉관통.
3D (FPS/TPS): VTB 발사 주도, PLB 전투 수치 중 확인 가능한 자사 보정만 원복, 샷건 추가 관통 차단, Mastery 과잉관통 차단. 근접 스플래시·내구도 회복 유지.
자바 브리지 부재 또는 VTB 비활성: PLB 폴백.
전환은 10 게임 틱마다 또는 공격 시 확인. 플레이어가 손에 든 무기만 조정하며 매 시점 전환마다 인벤토리 전체 스캔 없음.
상태 로그: [PartnerViewpointBridge], [PartnerLightweightBallistics] ballistics owner.
브리지 진단: B.Status() Lua 호출 가능 (PartnerViewpointBallisticsBridge.Status()).

중요한 한계: 이미 설치된 다른 모드가 무기 수치를 수정했거나 부착물이 있는 경우 안전을 위해 원복을 건너뛸 수 있다. 특히 예전 세이브의 부착물 총기는 선별 확인 필요.
인게임 'VTB_status()'로 Java patches live / disabled 상태 별도 확인 필요.
신규 게임/복제 세이브에서 3D 명중/관통이 실제 한 번만 적용되는지 검증 전 정식 사용 금지.
