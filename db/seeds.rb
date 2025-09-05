# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "シードデータの作成を開始します..."

# 既存のデータをクリア
Vote.destroy_all
Choice.destroy_all
Poll.destroy_all

# サンプルPoll 1: オープン状態の投票
poll1 = Poll.create!(
  title: "好きなプログラミング言語は？",
  description: "最も好きなプログラミング言語を選んでください。",
  status: :open,
  ends_at: 7.days.from_now
)

["Ruby", "Python", "JavaScript", "Go", "Rust", "その他"].each do |label|
  poll1.choices.create!(label: label)
end

puts "Poll '#{poll1.title}' を作成しました（選択肢: #{poll1.choices.count}個）"

# サンプルPoll 2: ドラフト状態の投票
poll2 = Poll.create!(
  title: "次回の開発勉強会のテーマ",
  description: "次回の社内勉強会で扱いたいテーマを選んでください。",
  status: :draft,
  ends_at: 14.days.from_now
)

["テスト駆動開発", "マイクロサービス", "AI/機械学習", "セキュリティ", "パフォーマンス最適化"].each do |label|
  poll2.choices.create!(label: label)
end

puts "Poll '#{poll2.title}' を作成しました（選択肢: #{poll2.choices.count}個）"

# サンプルPoll 3: 終了した投票
poll3 = Poll.create!(
  title: "リモートワークの頻度",
  description: "理想的なリモートワークの頻度はどのくらいですか？",
  status: :closed,
  ends_at: 1.day.ago
)

choices = ["完全リモート", "週3-4日", "週1-2日", "月数回", "出社のみ"].map do |label|
  poll3.choices.create!(label: label)
end

# サンプル投票データを追加（終了済みなのでvalidationをスキップ）
choices.each_with_index do |choice, index|
  (index + 1).times do
    vote = Vote.new(
      poll: poll3,
      choice: choice,
      voter_hash: SecureRandom.hex(16)
    )
    vote.save!(validate: false)
    choice.increment!(:votes_count)
  end
end

puts "Poll '#{poll3.title}' を作成しました（選択肢: #{poll3.choices.count}個、投票数: #{poll3.votes.count}）"

puts "\nシードデータの作成が完了しました！"
puts "作成されたPoll: #{Poll.count}個"
puts "作成されたChoice: #{Choice.count}個"
puts "作成されたVote: #{Vote.count}個"
