# ECR Repository Module - Test Migration Guide

このガイドでは、ECRリポジトリモジュールのテストをBashスクリプトベースからTerraform公式テストフレームワーク（.tftest.hcl）に移行した内容について説明します。

## 移行の概要

### 移行前（Bashスクリプトベース）
- `test_runner.sh` - メインのテストランナー
- `tests/test_*.sh` - 個別のテストスクリプト
- 外部ツール（terraform, aws cli, jq）に依存
- 手動でのテスト環境管理

### 移行後（Terraform公式テストフレームワーク）
- `*.tftest.hcl` - 宣言的なテストファイル
- 統合されたテスト実行環境
- モック機能による単体テスト
- 自動的なリソース管理

## 新しいテストファイル構成

### 1. basic.tftest.hcl
基本的なECRリポジトリの作成とメイン機能のテスト

**テスト内容:**
- 基本的なリポジトリ作成
- カスタムリポジトリ名
- イメージタグの変更可能性（MUTABLE/IMMUTABLE）
- KMS暗号化
- ライフサイクルポリシー
- リポジトリポリシー
- 出力値の確認
- タグの確認

### 2. validation.tftest.hcl
入力変数のバリデーションルールのテスト

**テスト内容:**
- 環境名の妥当性検証（dev, stg, prd, rls）
- イメージタグ変更可能性の妥当性検証
- 暗号化タイプの妥当性検証
- KMSキーの必須性検証
- レプリケーション先リージョンの形式検証
- 共通タグの必須キー検証

### 3. multiple_repositories.tftest.hcl
複数リポジトリ作成機能のテスト

**テスト内容:**
- 複数リポジトリの同時作成
- リポジトリごとの異なる設定
- KMS暗号化の個別設定
- オプションパラメータのデフォルト値
- 複数リポジトリの出力値
- 単一リポジトリ出力値のnull確認

### 4. integration.tftest.hcl
実際のAWSリソースを使用した統合テスト

**テスト内容:**
- 実際のECRリポジトリ作成
- ライフサイクルポリシーの実際の適用
- リポジトリポリシーの実際の適用
- タグの実際の設定確認
- イメージURIの形式確認

### 5. mocks.tftest.hcl
モックプロバイダーの設定

**提供内容:**
- AWS認証情報のモック
- データソースのモック（aws_caller_identity, aws_region）
- リソースのデフォルト値設定

## テスト実行方法

### 単体テスト（モック使用）
```bash
# 全ての単体テストを実行
terraform test basic.tftest.hcl validation.tftest.hcl multiple_repositories.tftest.hcl

# 特定のテストファイルのみ実行
terraform test basic.tftest.hcl

# 特定のテストケースのみ実行
terraform test -filter="basic_repository_creation"
```

### 統合テスト（実際のAWS使用）
```bash
# AWS認証情報が設定されている環境で実行
terraform test integration.tftest.hcl
```

## 移行のメリット

### 1. 統合されたテスト環境
- Terraformに組み込まれたテストフレームワーク
- 外部ツールへの依存減少
- 一貫したテスト実行方法

### 2. 宣言的なテスト定義
- HCL形式での読みやすいテスト定義
- アサーション機能による明確な検証
- 条件分岐やループの簡素化

### 3. モック機能
- AWS認証情報不要での単体テスト
- 高速なテスト実行
- 外部依存の排除

### 4. 自動リソース管理
- テストリソースの自動作成・削除
- 状態管理の自動化
- クリーンアップの確実性

### 5. 強化されたアサーション
- リソース属性の直接検証
- 出力値の型安全な確認
- 複雑な条件の表現力向上

## 移行前後の比較

| 項目           | 移行前（Bashスクリプト） | 移行後（.tftest.hcl） |
| -------------- | ------------------------ | --------------------- |
| テスト定義     | Bashスクリプト           | HCL（宣言的）         |
| 依存関係       | terraform, aws cli, jq   | terraform のみ        |
| モック         | 困難                     | 組み込みサポート      |
| アサーション   | 手動実装                 | 組み込み機能          |
| リソース管理   | 手動                     | 自動                  |
| 実行速度       | 遅い（API呼び出し）      | 高速（モック使用）    |
| 並列実行       | 手動実装                 | 自動サポート          |
| エラーレポート | 基本的                   | 詳細で構造化          |

## 従来のテストとの互換性

移行期間中は、従来のBashスクリプトテストも併用可能です：

```bash
# 従来のテスト実行
./test_runner.sh

# 新しいテスト実行
terraform test
```

## 今後の展開

1. **他のモジュールへの展開**
   - ECSモジュール
   - ALBモジュール
   - EC2モジュール
   - Analyticsモジュール

2. **テストの拡張**
   - パフォーマンステスト
   - セキュリティテスト
   - 互換性テスト

3. **CI/CDパイプラインの統合**
   - GitHub Actions / GitLab CI での自動実行
   - テスト結果のレポート生成
   - カバレッジ測定

## 参考リンク

- [Terraform Test Framework Documentation](https://developer.hashicorp.com/terraform/language/tests)
- [Terraform Mock Providers](https://developer.hashicorp.com/terraform/language/tests/mocking)
- [ECR Repository Module Documentation](./README.md)

## 移行完了日

2024年7月7日 - ECRリポジトリモジュールのテスト移行完了
