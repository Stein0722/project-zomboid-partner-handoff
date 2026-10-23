Partner VSGirl Render Guard 1.0.1

- VSGirlBodyExtension이 렌더 스레드에서 착용 목록을 읽는 순간 목록이 바뀌어도 게임이 튕기지 않게 합니다.
- TextureCaps.worn, Physics.wearsBra, Physics.capFit에서 발생한 예외만 안전한 false 값으로 바꿉니다.
- Physics.clothingCoverage에서 옷 목록이 순간적으로 흔들리면 그 한 프레임만 안전한 기본 피복값으로 넘깁니다.
- 정상적인 바디, 의상, 물리 효과에는 손대지 않습니다.
- 원본 VSGirlBodyExtension 파일을 수정하지 않습니다.

검증 상태
- B42.21 최신 로그에서 JAR와 보호 패치 4개의 로딩을 확인했습니다.
- 같은 렌더 예외의 재발은 최신 로그에서 보이지 않았습니다.
- 장시간 의상 교체·전투 반복 검증은 아직 완료하지 않았습니다.

필수 모드
- ZombieBuddy
- VSGirlBodyExtension
