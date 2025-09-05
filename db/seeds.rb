# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# ---- Sample data for development/test ----
return if defined?(Poll).nil?

if Poll.where(slug: "sample-poll").blank?
  poll = Poll.create!(
    title: "あなたが好きな色は？",
    description: "最も好きな色を1つ選んでください。",
    slug: "sample-poll",
    status: :open,
    ends_at: 7.days.from_now
  )

  %w[青 赤 緑 その他].each do |label|
    poll.choices.create!(label: label)
  end
end
