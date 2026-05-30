# 单元测试模板与策略

## 测试策略

- **优先级**：Service 层单元测试 > Controller 层集成测试
- **Mock 策略**：Mock 外部依赖（Repository、Redis、MinIO、LLM），测试业务逻辑
- **命名规范**：`方法名_场景_预期结果`（如 `create_whenNameExists_throwBusinessException`）

## Service 单测模板

```java
@ExtendWith(MockitoExtension.class)
class XxxServiceTest {

    @InjectMocks
    private XxxService xxxService;

    @Mock
    private XxxRepository xxxRepository;

    @Mock
    private XxxMapper xxxMapper;

    @Test
    void findAll_shouldReturnPagedResult() {
        // Given
        var entity = new XxxEntity();
        entity.setId(1L);
        entity.setName("test");
        var page = new PageImpl<>(List.of(entity));
        when(xxxRepository.findByProjectGroupId(any(), any())).thenReturn(page);

        // When
        var result = xxxService.findAll(null, PageRequest.of(0, 20));

        // Then
        assertThat(result.getContent()).hasSize(1);
        assertThat(result.getContent().get(0).getName()).isEqualTo("test");
    }

    @Test
    void create_whenDuplicateName_shouldThrowBusinessException() {
        // Given
        when(xxxRepository.existsByNameAndProjectGroupId("dup", 1L)).thenReturn(true);
        var dto = new XxxDTO();
        dto.setName("dup");
        dto.setProjectGroupId(1L);

        // When & Then
        assertThatThrownBy(() -> xxxService.create(dto))
            .isInstanceOf(BusinessException.class);
    }
}
```

## Controller 集成测试模板（可选）

```java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class XxxControllerTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private XxxRepository xxxRepository;

    @BeforeEach
    void setUp() {
        xxxRepository.deleteAll();
    }

    @Test
    void findAll_shouldReturn200() {
        var response = restTemplate.getForEntity("/api/admin/xxx", PageResult.class);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
    }
}
```

## Mock 常见外部依赖

| 依赖 | Mock 方式 |
|------|---------|
| Repository/Mapper | `@Mock` + `when().thenReturn()` |
| LlmProviderRegistry | `@Mock` + mock ChatClient 返回值 |
| RedisService | `@Mock` + `when().thenReturn()` |
| MinioService | `@Mock` + `when().thenReturn()` |
| FeishuMessageService | `@Mock` + `doNothing().when()` |

## 测试文件位置

```
src/test/java/com/bot/
├── common/
│   └── ai/
│       └── PromptSanitizerTest.java
├── modules/
│   ├── session/
│   │   └── SessionServiceTest.java
│   ├── classification/
│   │   └── ClassificationServiceTest.java
│   └── ...
└── infrastructure/
    └── redis/
        └── RedisServiceTest.java
```

## verifier Agent 写单测的步骤

1. 读取 coder Agent 变更的 Service 类
2. 识别 public 方法（排除 getter/setter）
3. 为每个方法编写 2-3 个测试用例（正常路径 + 边界 + 异常）
4. 创建测试文件到 `src/test/java/com/bot/modules/<module>/`
5. 运行 `mvn test -pl . -Dtest=<TestClass>` 验证
