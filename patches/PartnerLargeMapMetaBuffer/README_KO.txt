Partner Large Map Metadata Buffer 1.0.1

대상: Project Zomboid Build 42.21 + ZombieBuddy

기능
- 게임의 지도 메타데이터 임시 버퍼를 10 MiB에서 64 MiB로 늘립니다.
- 대구처럼 매우 큰 지도와 여러 모드맵을 함께 쓸 때 map_meta.bin 저장이
  BufferOverflowException으로 실패하는 문제를 막습니다.
- 맵 파일, 월드 타일, 캐릭터 데이터는 수정하지 않습니다.

주의
- 이 패치는 이미 0바이트가 된 map_meta.bin을 복구하지 않습니다.
- 적용 뒤 새 지구에서 테스트해야 합니다.
- 기본 모드 목록에서 ZombieBuddy와 함께 켜야 합니다.

복구
- 기본 모드 목록에서 Partner Large Map Metadata Buffer를 끄면 됩니다.
