# 03_statistical_comparison.py
# Statistical Comparison of Quality Control Scores Across Prompts
# Tim Fraser

# This script demonstrates how to use t-test and ANOVA to compare quality control
# scores for reports generated from different prompts. Students learn to perform
# statistical hypothesis testing to determine if prompt differences are significant.

# 0. Setup #################################

## 0.1 Import Packages #################################

# If you haven't already, install required packages:
# pip install pandas scipy statsmodels

import sys

# UTF-8 stdout on Windows so emoji/log text prints reliably in the terminal
if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

import numpy as np
import pandas as pd
from scipy.stats import bartlett, f_oneway, ttest_ind
from statsmodels.stats.oneway import anova_oneway

## 0.2 Load Quality Control Scores #################################

# Load pre-computed quality control scores for reports from 3 different prompts
# Each prompt generated 30 reports, and each report was evaluated on multiple criteria
scores = pd.read_csv("09_text_analysis/data/prompt_comparison_scores.csv")

# Format p-values so very small values do not print as 0 after rounding


def fmt_p(p):
    if p is None or (isinstance(p, float) and np.isnan(p)):
        return str(p)
    return f"{p:.2e}" if p < 1e-4 else f"{p:.4f}"


# View the data structure
print("📊 Quality Control Scores Dataset:")
print(scores.head())
print(f"\nShape: {scores.shape}")
print(f"Columns: {list(scores.columns)}\n")

# 1. Descriptive Statistics #################################

## 1.1 Summary Statistics by Prompt #################################

# Calculate mean overall scores by prompt
# This gives us a first look at whether prompts differ in quality
summary_stats = scores.groupby("prompt_id").agg({
    "overall_score": ["mean", "std"],
    "formality": "mean",
    "succinctness": "mean",
    "clarity": "mean",
}).round(2)

print("📈 Summary Statistics by Prompt:")
print(summary_stats)
print()

# Overall mean across all prompts
overall_mean = scores["overall_score"].mean()
print(f"📊 Overall Mean Score (all prompts): {overall_mean:.2f}\n")

## 1.2 Visual Inspection #################################

# Calculate means and standard deviations for each prompt
# This helps us see if there are obvious differences between prompts
for prompt in ["A", "B", "C"]:
    prompt_scores = scores.query(f'prompt_id == "{prompt}"')["overall_score"]
    print(f"📊 Prompt {prompt}: Mean = {prompt_scores.mean():.2f}, SD = {prompt_scores.std():.2f}")
print()

# 2. Testing Assumptions #################################

## 2.1 Homogeneity of Variance (Bartlett's Test) #################################

# Before running ANOVA, we need to check if the variances are equal across groups
# Bartlett's test checks whether the variances of our 3 groups are significantly different

a = scores.query('prompt_id == "A"')["overall_score"]
b = scores.query('prompt_id == "B"')["overall_score"]
c = scores.query('prompt_id == "C"')["overall_score"]

b_stat, b_p_value = bartlett(a, b, c)

print("🔍 Bartlett's Test for Homogeneity of Variance:")
print(f"   Bartlett's test statistic: {b_stat:.4f}")
print(f"   p-value: {fmt_p(b_p_value)}\n")

# If p-value < 0.05, variances are significantly different (don't assume equal variance)
# If p-value >= 0.05, variances are not significantly different (can assume equal variance)
var_equal = b_p_value >= 0.05
print(
    f"📊 Equal Variance Assumption: {'✅ Can assume equal variance' if var_equal else '❌ Do NOT assume equal variance'}"
)
print(f"   (p-value = {fmt_p(b_p_value)})\n")

# 3. Two-Group Comparison: T-Test #################################

## 3.1 Compare Prompt A vs Prompt B #################################

prompt_a_scores = scores.query('prompt_id == "A"')["overall_score"]
prompt_b_scores = scores.query('prompt_id == "B"')["overall_score"]

print("📊 T-Test: Prompt A vs Prompt B")
print(f"   Mean A: {prompt_a_scores.mean():.2f}")
print(f"   Mean B: {prompt_b_scores.mean():.2f}")
print(f"   Difference: {prompt_a_scores.mean() - prompt_b_scores.mean():.2f}\n")

# Student's t-test if equal variances; Welch's t-test if not (equal_var=False)
t_res = ttest_ind(prompt_a_scores, prompt_b_scores, equal_var=var_equal, nan_policy="omit")

print("📋 T-Test Results:")
print(f"   statistic (t): {t_res.statistic:.4f}")
print(f"   p-value: {fmt_p(t_res.pvalue)}\n")

p_value_t = float(t_res.pvalue)

print("💡 Interpretation:")
if p_value_t < 0.05:
    better = "A" if prompt_a_scores.mean() > prompt_b_scores.mean() else "B"
    print("   ✅ The difference between Prompt A and Prompt B is statistically significant.")
    print(f"   ✅ Prompt {better} performs significantly better (p = {fmt_p(p_value_t)}).")
else:
    print("   ❌ The difference between Prompt A and Prompt B is NOT statistically significant.")
    print(f"   ❌ We cannot conclude that one prompt performs better than the other (p = {fmt_p(p_value_t)}).")
print()

# 4. Three-Group Comparison: ANOVA #################################

## 4.1 One-Way ANOVA #################################

# Compare all three prompts: standard ANOVA if equal variances; Welch otherwise
if var_equal:
    anova_res = f_oneway(a, b, c)
    f_statistic = float(anova_res.statistic)
    p_value = float(anova_res.pvalue)
    print("📊 ANOVA: Comparing All Three Prompts (A, B, C) - Equal Variances Assumed")
else:
    welch = anova_oneway([a.values, b.values, c.values], use_var="unequal")
    f_statistic = float(welch.statistic)
    p_value = float(welch.pvalue)
    print("📊 ANOVA: Comparing All Three Prompts (A, B, C) - Unequal Variances (Welch's ANOVA)")

print(f"\n📋 ANOVA Results:\n   F-statistic: {f_statistic:.4f}\n   p-value: {fmt_p(p_value)}\n")

## 4.2 Interpret ANOVA Results #################################

print("💡 Interpretation:")
if p_value < 0.05:
    print("   ✅ At least one prompt performs significantly differently from the others.")
    print(f"   ✅ The F-statistic ({f_statistic:.4f}) is significant (p = {fmt_p(p_value)}).")
    print("   ✅ We can conclude that prompt choice significantly affects quality control scores.")
else:
    print("   ❌ We cannot conclude that prompts differ significantly.")
    print(f"   ❌ The F-statistic ({f_statistic:.4f}) is not significant (p = {fmt_p(p_value)}).")
    print("   ❌ Prompt choice does not appear to significantly affect quality control scores.")
print()

# 5. Comparing Specific Quality Dimensions #################################

## 5.1 Formality Comparison #################################

# Compare formality scores across prompts
print("📊 Formality Scores by Prompt:")
formality_stats = scores.groupby("prompt_id")["formality"].agg(["mean", "std"]).round(2)
print(formality_stats)
print()

fa = scores.query('prompt_id == "A"')["formality"]
fb = scores.query('prompt_id == "B"')["formality"]
fc = scores.query('prompt_id == "C"')["formality"]
formality_f = f_oneway(fa, fb, fc)
print("📋 Formality ANOVA Results (one-way, equal-variance):")
print(f"   F-statistic: {formality_f.statistic:.4f}, p-value: {fmt_p(formality_f.pvalue)}\n")

## 5.2 Succinctness Comparison #################################

# Compare succinctness scores across prompts (Prompt B has zero within-group variance)
print("📊 Succinctness Scores by Prompt:")
succinctness_stats = scores.groupby("prompt_id")["succinctness"].agg(["mean", "std"]).round(2)
print(succinctness_stats)
print()

sa = scores.query('prompt_id == "A"')["succinctness"]
sb = scores.query('prompt_id == "B"')["succinctness"]
sc = scores.query('prompt_id == "C"')["succinctness"]
succinctness_f = f_oneway(sa, sb, sc)
print("📋 Succinctness ANOVA Results (one-way; classic ANOVA when one group has zero spread):")
print(f"   F-statistic: {succinctness_f.statistic:.4f}, p-value: {fmt_p(succinctness_f.pvalue)}\n")

print("✅ Statistical comparison complete!")
print("💡 Key takeaway: Use these statistical tests to determine if prompt differences")
print("   are statistically significant, not just due to random variation.")
