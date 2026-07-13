#!/usr/bin/env python3
"""
=============================================================================
student_predictive.py
Purpose : Predictive analysis of BigData_Student_Performance_Dataset_1000
Models  :
  Part A – GPA Regression        (Linear Reg, Random Forest, Gradient Boosting)
  Part B – Grade Classification  (Logistic Reg, Random Forest, Gradient Boosting)
  Part C – Placement Prediction  (Logistic Reg, Random Forest)
Output  : Console metrics + plots saved to scripts/output/
=============================================================================
"""

import os, sys, warnings
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')            # non-interactive backend for WSL
import matplotlib.pyplot as plt
import seaborn as sns

from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.linear_model import LinearRegression, LogisticRegression
from sklearn.ensemble import RandomForestRegressor, RandomForestClassifier
from sklearn.ensemble import GradientBoostingRegressor, GradientBoostingClassifier
from sklearn.metrics import (
    mean_squared_error, mean_absolute_error, r2_score,
    accuracy_score, f1_score, classification_report,
    confusion_matrix, roc_auc_score, ConfusionMatrixDisplay
)
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import OneHotEncoder, OrdinalEncoder

warnings.filterwarnings('ignore')

# ── Output directory ──────────────────────────────────────────────────────────
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OUT_DIR    = os.path.join(SCRIPT_DIR, 'output')
os.makedirs(OUT_DIR, exist_ok=True)

# Data path (try HDFS-mounted CSV first, then local)
DATA_PATHS = [
    '/mnt/c/bigdata/big-data-analytics-group-assignemnt/data/BigData_Student_Performance_Dataset_1000.xlsx',
    os.path.join(SCRIPT_DIR, '..', 'data', 'BigData_Student_Performance_Dataset_1000.xlsx'),
    '/mnt/c/bigdata/big-data-analytics-group-assignemnt/data/student_performance.csv',
    os.path.join(SCRIPT_DIR, '..', 'data', 'student_performance.csv'),
]

def sep(title):
    print(f"\n{'='*65}")
    print(f"  {title}")
    print('='*65)

# ── Load Data ─────────────────────────────────────────────────────────────────
def load_data():
    for p in DATA_PATHS:
        if os.path.exists(p):
            if p.endswith('.xlsx'):
                df = pd.read_excel(p)
            else:
                df = pd.read_csv(p)
            print(f"[✓] Loaded data from: {p}")
            return df
    raise FileNotFoundError("Dataset not found in any expected location.")

df_raw = load_data()
df_raw.columns = [c.strip().lower().replace(' ','_') for c in df_raw.columns]
print(f"Shape: {df_raw.shape}  |  Columns: {list(df_raw.columns)}")

# ── EDA ───────────────────────────────────────────────────────────────────────
sep("EXPLORATORY DATA ANALYSIS")

print(f"\nDtypes:\n{df_raw.dtypes}")
print(f"\nMissing values:\n{df_raw.isnull().sum()}")
print(f"\nBasic stats:\n{df_raw.describe()}")

# Rename columns to normalised names
col_map = {
    'student_id':'student_id','name':'name','gender':'gender','age':'age',
    'department':'department','program':'program','year':'year',
    'semester':'semester','attendance':'attendance','assignment':'assignment',
    'cat':'cat','finalexam':'finalexam','studyhours':'studyhours',
    'internetaccess':'internetaccess','device':'device',
    'parentincome':'parentincome','scholarship':'scholarship',
    'skillscount':'skillscount','projects':'projects',
    'lmslogins':'lmslogins','libraryvisits':'libraryvisits',
    'location':'location','graduated':'graduated','placement':'placement',
    'gpa':'gpa','total':'total','grade':'grade'
}
# Handle alternate column names from Excel version
alt_col_map = {
    'internet_access':'internetaccess','study_hours':'studyhours',
    'parent_income':'parentincome','skills_count':'skillscount',
    'library_visits':'libraryvisits','lms_logins':'lmslogins',
    'final_exam':'finalexam'
}
df_raw.rename(columns=alt_col_map, inplace=True)

# ── Clean / Feature-engineer ──────────────────────────────────────────────────
df = df_raw.copy()
# Standardise string categoricals
for c in ['gender','department','program','internetaccess','device',
          'scholarship','graduated','placement','grade','location']:
    if c in df.columns:
        df[c] = df[c].astype(str).str.strip().str.upper()

# Ensure numerics
num_cols = ['age','attendance','assignment','cat','finalexam','studyhours',
            'parentincome','skillscount','projects','lmslogins','libraryvisits','gpa','total','year','semester']
for c in num_cols:
    if c in df.columns:
        df[c] = pd.to_numeric(df[c], errors='coerce')

df.dropna(subset=['gpa','grade','placement'], inplace=True)
print(f"\nRows after cleaning: {len(df)}")

# ── Correlation heatmap ───────────────────────────────────────────────────────
sep("CORRELATION HEATMAP")
numeric_df = df.select_dtypes(include=np.number)
plt.figure(figsize=(14, 10))
mask = np.triu(np.ones_like(numeric_df.corr(), dtype=bool))
sns.heatmap(numeric_df.corr(), mask=mask, annot=True, fmt='.2f',
            cmap='coolwarm', linewidths=.5, annot_kws={'size':8})
plt.title('Correlation Matrix – Student Performance Features', fontsize=14)
plt.tight_layout()
plt.savefig(os.path.join(OUT_DIR, '01_correlation_heatmap.png'), dpi=150)
plt.close()
print("Saved: 01_correlation_heatmap.png")

# ── GPA Distribution ──────────────────────────────────────────────────────────
fig, axes = plt.subplots(1, 3, figsize=(16, 5))
df['gpa'].hist(bins=30, ax=axes[0], color='steelblue', edgecolor='white')
axes[0].set_title('GPA Distribution'); axes[0].set_xlabel('GPA')
df.groupby('grade')['gpa'].mean().sort_index().plot(kind='bar', ax=axes[1], color='coral')
axes[1].set_title('Average GPA by Grade'); axes[1].set_xlabel('Grade')
df.groupby('department')['gpa'].mean().sort_values().plot(kind='barh', ax=axes[2], color='teal')
axes[2].set_title('Average GPA by Department')
plt.tight_layout()
plt.savefig(os.path.join(OUT_DIR, '02_gpa_distributions.png'), dpi=150)
plt.close()
print("Saved: 02_gpa_distributions.png")

# ── Prepare feature sets ──────────────────────────────────────────────────────
# Columns to drop: ID, name, leakage (total/grade/gpa for regression on gpa, etc.)
DROP_ALWAYS = ['student_id', 'name']

CATEGORICAL = [c for c in ['gender','department','program','internetaccess',
                            'device','scholarship','location','graduated'] if c in df.columns]
NUMERIC     = [c for c in ['age','attendance','assignment','cat','finalexam',
                            'studyhours','parentincome','skillscount','projects',
                            'lmslogins','libraryvisits','year','semester'] if c in df.columns]

def build_preprocessor(num_cols, cat_cols):
    return ColumnTransformer([
        ('num', StandardScaler(), num_cols),
        ('cat', OneHotEncoder(handle_unknown='ignore', sparse_output=False), cat_cols),
    ])

def plot_confusion(cm, labels, title, fname):
    plt.figure(figsize=(8, 6))
    disp = ConfusionMatrixDisplay(confusion_matrix=cm, display_labels=labels)
    disp.plot(cmap='Blues', colorbar=False)
    plt.title(title)
    plt.tight_layout()
    plt.savefig(os.path.join(OUT_DIR, fname), dpi=150)
    plt.close()
    print(f"Saved: {fname}")

def plot_feature_importance(model, feature_names, title, fname, top_n=20):
    try:
        imp = pd.Series(model.feature_importances_, index=feature_names).nlargest(top_n)
        plt.figure(figsize=(10, 6))
        imp.sort_values().plot(kind='barh', color='steelblue')
        plt.title(title); plt.xlabel('Importance')
        plt.tight_layout()
        plt.savefig(os.path.join(OUT_DIR, fname), dpi=150)
        plt.close()
        print(f"Saved: {fname}")
    except Exception as e:
        print(f"[!] Could not plot feature importance: {e}")

results_summary = []

# =============================================================================
# PART A – GPA REGRESSION
# =============================================================================
sep("PART A: GPA REGRESSION")

# Features: drop total (direct linear combo with GPA) and grade (derived)
feat_cols_reg = NUMERIC + CATEGORICAL
# also drop 'placement' and 'graduated' to avoid leakage
feat_cols_reg = [c for c in feat_cols_reg if c not in ['total','grade','placement','graduated']]

X_reg = df[feat_cols_reg].copy()
y_reg = df['gpa'].copy()

num_reg = [c for c in feat_cols_reg if c in NUMERIC]
cat_reg = [c for c in feat_cols_reg if c in CATEGORICAL]

X_train_r, X_temp_r, y_train_r, y_temp_r = train_test_split(X_reg, y_reg, test_size=0.30, random_state=42)
X_val_r,   X_test_r, y_val_r,   y_test_r = train_test_split(X_temp_r, y_temp_r, test_size=0.50, random_state=42)

print(f"Train/Val/Test sizes: {len(X_train_r)} / {len(X_val_r)} / {len(X_test_r)}")

pre_r = build_preprocessor(num_reg, cat_reg)

reg_models = {
    'Linear Regression'       : LinearRegression(),
    'Random Forest Regressor' : RandomForestRegressor(n_estimators=200, random_state=42, n_jobs=-1),
    'Gradient Boosting Reg'   : GradientBoostingRegressor(n_estimators=200, learning_rate=0.05, random_state=42),
}

reg_results = {}
for name, model in reg_models.items():
    pipe = Pipeline([('pre', pre_r), ('model', model)])
    pipe.fit(X_train_r, y_train_r)
    y_pred_val = pipe.predict(X_val_r)
    y_pred_tst = pipe.predict(X_test_r)
    rmse_val = np.sqrt(mean_squared_error(y_val_r, y_pred_val))
    mae_val  = mean_absolute_error(y_val_r, y_pred_val)
    r2_val   = r2_score(y_val_r, y_pred_val)
    rmse_tst = np.sqrt(mean_squared_error(y_test_r, y_pred_tst))
    r2_tst   = r2_score(y_test_r, y_pred_tst)
    reg_results[name] = {'val_RMSE': rmse_val, 'val_MAE': mae_val, 'val_R2': r2_val,
                         'test_RMSE': rmse_tst, 'test_R2': r2_tst, 'pipe': pipe,
                         'y_pred_test': y_pred_tst}
    print(f"\n[{name}]")
    print(f"  Val   RMSE={rmse_val:.4f}  MAE={mae_val:.4f}  R²={r2_val:.4f}")
    print(f"  Test  RMSE={rmse_tst:.4f}  R²={r2_tst:.4f}")
    results_summary.append({'Task':'GPA Regression','Model':name,
                             'Val_RMSE':round(rmse_val,4),'Val_R2':round(r2_val,4),
                             'Test_RMSE':round(rmse_tst,4),'Test_R2':round(r2_tst,4)})

# Best regression model
best_reg_name = min(reg_results, key=lambda k: reg_results[k]['test_RMSE'])
best_reg = reg_results[best_reg_name]
print(f"\n✓ Best Regression Model: {best_reg_name}  (Test RMSE={best_reg['test_RMSE']:.4f}, R²={best_reg['test_R2']:.4f})")

# Actual vs Predicted plot
plt.figure(figsize=(8, 6))
plt.scatter(y_test_r, best_reg['y_pred_test'], alpha=0.5, color='steelblue', s=20)
mn, mx = y_test_r.min(), y_test_r.max()
plt.plot([mn, mx], [mn, mx], 'r--', lw=2)
plt.xlabel('Actual GPA'); plt.ylabel('Predicted GPA')
plt.title(f'Actual vs Predicted GPA — {best_reg_name}')
plt.tight_layout()
plt.savefig(os.path.join(OUT_DIR, '03_gpa_actual_vs_pred.png'), dpi=150)
plt.close()
print("Saved: 03_gpa_actual_vs_pred.png")

# Feature importance
best_pipe_r = best_reg['pipe']
ohe_feats = best_pipe_r.named_steps['pre'].named_transformers_['cat']\
            .get_feature_names_out(cat_reg).tolist()
all_feat_names = num_reg + ohe_feats
plot_feature_importance(best_pipe_r.named_steps['model'], all_feat_names,
                        f'Feature Importance – {best_reg_name}',
                        '04_gpa_feature_importance.png')

# Validation RMSE comparison bar chart
plt.figure(figsize=(8, 5))
names = list(reg_results.keys())
rmse_vals = [reg_results[n]['val_RMSE'] for n in names]
plt.bar(names, rmse_vals, color=['steelblue','coral','seagreen'])
plt.xticks(rotation=15, ha='right')
plt.ylabel('RMSE (lower is better)')
plt.title('GPA Regression Model Comparison – Validation RMSE')
plt.tight_layout()
plt.savefig(os.path.join(OUT_DIR, '05_gpa_model_comparison.png'), dpi=150)
plt.close()
print("Saved: 05_gpa_model_comparison.png")

# =============================================================================
# PART B – GRADE CLASSIFICATION
# =============================================================================
sep("PART B: GRADE CLASSIFICATION (A/B/C/D/F)")

# Drop leakage columns: total, gpa (directly determine grade), placement
feat_cols_cls = [c for c in NUMERIC + CATEGORICAL
                 if c not in ['total','gpa','placement','graduated']]
X_cls = df[feat_cols_cls].copy()
y_cls = df['grade'].copy()

num_cls = [c for c in feat_cols_cls if c in NUMERIC]
cat_cls = [c for c in feat_cols_cls if c in CATEGORICAL]

X_train_c, X_temp_c, y_train_c, y_temp_c = train_test_split(X_cls, y_cls, test_size=0.30,
                                                              random_state=42, stratify=y_cls)
X_val_c,   X_test_c, y_val_c,   y_test_c = train_test_split(X_temp_c, y_temp_c, test_size=0.50,
                                                              random_state=42, stratify=y_temp_c)
print(f"Train/Val/Test sizes: {len(X_train_c)} / {len(X_val_c)} / {len(X_test_c)}")
print(f"Grade distribution:\n{y_cls.value_counts().sort_index()}")

pre_c = build_preprocessor(num_cls, cat_cls)

cls_models = {
    'Logistic Regression'      : LogisticRegression(max_iter=1000, random_state=42),
    'Random Forest Classifier' : RandomForestClassifier(n_estimators=200, random_state=42, n_jobs=-1),
    'Gradient Boosting Cls'    : GradientBoostingClassifier(n_estimators=200, learning_rate=0.05, random_state=42),
}

cls_results = {}
for name, model in cls_models.items():
    pipe = Pipeline([('pre', pre_c), ('model', model)])
    pipe.fit(X_train_c, y_train_c)
    y_pred_val = pipe.predict(X_val_c)
    y_pred_tst = pipe.predict(X_test_c)
    acc_val = accuracy_score(y_val_c, y_pred_val)
    f1_val  = f1_score(y_val_c, y_pred_val, average='weighted')
    acc_tst = accuracy_score(y_test_c, y_pred_tst)
    f1_tst  = f1_score(y_test_c, y_pred_tst, average='weighted')
    cls_results[name] = {'val_acc': acc_val, 'val_f1': f1_val,
                         'test_acc': acc_tst, 'test_f1': f1_tst,
                         'pipe': pipe, 'y_pred_test': y_pred_tst}
    print(f"\n[{name}]")
    print(f"  Val   Acc={acc_val:.4f}  F1(weighted)={f1_val:.4f}")
    print(f"  Test  Acc={acc_tst:.4f}  F1={f1_tst:.4f}")
    print(classification_report(y_test_c, y_pred_tst, zero_division=0))
    results_summary.append({'Task':'Grade Classification','Model':name,
                             'Val_Acc':round(acc_val,4),'Val_F1':round(f1_val,4),
                             'Test_Acc':round(acc_tst,4),'Test_F1':round(f1_tst,4)})

best_cls_name = max(cls_results, key=lambda k: cls_results[k]['test_f1'])
best_cls = cls_results[best_cls_name]
print(f"\n✓ Best Classification Model: {best_cls_name}  (Test Acc={best_cls['test_acc']:.4f}, F1={best_cls['test_f1']:.4f})")

# Confusion matrix for best model
grade_labels = sorted(y_cls.unique())
cm = confusion_matrix(y_test_c, best_cls['y_pred_test'], labels=grade_labels)
plot_confusion(cm, grade_labels,
               f'Confusion Matrix – Grade Classification ({best_cls_name})',
               '06_grade_confusion_matrix.png')

# Feature importance
ohe_feats_c = best_cls['pipe'].named_steps['pre'].named_transformers_['cat']\
              .get_feature_names_out(cat_cls).tolist()
all_feat_names_c = num_cls + ohe_feats_c
plot_feature_importance(best_cls['pipe'].named_steps['model'], all_feat_names_c,
                        f'Feature Importance – Grade Classification ({best_cls_name})',
                        '07_grade_feature_importance.png')

# Model accuracy comparison bar chart
plt.figure(figsize=(8, 5))
names_c = list(cls_results.keys())
accs    = [cls_results[n]['test_acc'] for n in names_c]
f1s     = [cls_results[n]['test_f1']  for n in names_c]
x = np.arange(len(names_c)); w = 0.35
plt.bar(x - w/2, accs, w, label='Accuracy', color='steelblue')
plt.bar(x + w/2, f1s,  w, label='F1 (weighted)', color='coral')
plt.xticks(x, names_c, rotation=15, ha='right')
plt.ylabel('Score'); plt.ylim(0, 1)
plt.title('Grade Classification Model Comparison')
plt.legend(); plt.tight_layout()
plt.savefig(os.path.join(OUT_DIR, '08_grade_model_comparison.png'), dpi=150)
plt.close()
print("Saved: 08_grade_model_comparison.png")

# =============================================================================
# PART C – PLACEMENT PREDICTION (Binary)
# =============================================================================
sep("PART C: PLACEMENT PREDICTION (YES / NO)")

feat_cols_pl = [c for c in NUMERIC + CATEGORICAL
                if c not in ['total','gpa','grade','graduated']]
X_pl = df[feat_cols_pl].copy()
y_pl = (df['placement'] == 'YES').astype(int)

num_pl = [c for c in feat_cols_pl if c in NUMERIC]
cat_pl = [c for c in feat_cols_pl if c in CATEGORICAL]

print(f"Placement distribution:\n{y_pl.value_counts()}")

X_train_p, X_temp_p, y_train_p, y_temp_p = train_test_split(X_pl, y_pl, test_size=0.30,
                                                              random_state=42, stratify=y_pl)
X_val_p,   X_test_p, y_val_p,   y_test_p = train_test_split(X_temp_p, y_temp_p, test_size=0.50,
                                                              random_state=42, stratify=y_temp_p)
print(f"Train/Val/Test sizes: {len(X_train_p)} / {len(X_val_p)} / {len(X_test_p)}")

pre_p = build_preprocessor(num_pl, cat_pl)

pl_models = {
    'Logistic Regression'      : LogisticRegression(max_iter=1000, random_state=42),
    'Random Forest Classifier' : RandomForestClassifier(n_estimators=200, random_state=42, n_jobs=-1),
}

pl_results = {}
for name, model in pl_models.items():
    pipe = Pipeline([('pre', pre_p), ('model', model)])
    pipe.fit(X_train_p, y_train_p)
    y_pred_val  = pipe.predict(X_val_p)
    y_pred_tst  = pipe.predict(X_test_p)
    try:
        y_prob_tst = pipe.predict_proba(X_test_p)[:, 1]
        auc_tst = roc_auc_score(y_test_p, y_prob_tst)
    except Exception:
        auc_tst = float('nan')
    acc_tst = accuracy_score(y_test_p, y_pred_tst)
    f1_tst  = f1_score(y_test_p, y_pred_tst)
    pl_results[name] = {'test_acc': acc_tst, 'test_f1': f1_tst, 'test_auc': auc_tst,
                        'pipe': pipe, 'y_pred_test': y_pred_tst}
    print(f"\n[{name}]")
    print(f"  Test  Acc={acc_tst:.4f}  F1={f1_tst:.4f}  ROC-AUC={auc_tst:.4f}")
    print(classification_report(y_test_p, y_pred_tst, target_names=['Not Placed','Placed'], zero_division=0))
    results_summary.append({'Task':'Placement Prediction','Model':name,
                             'Test_Acc':round(acc_tst,4),'Test_F1':round(f1_tst,4),
                             'Test_ROC_AUC':round(auc_tst,4)})

best_pl_name = max(pl_results, key=lambda k: pl_results[k]['test_auc'])
best_pl = pl_results[best_pl_name]
print(f"\n✓ Best Placement Model: {best_pl_name}  (AUC={best_pl['test_auc']:.4f})")

# Confusion matrix
cm_pl = confusion_matrix(y_test_p, best_pl['y_pred_test'])
plot_confusion(cm_pl, ['Not Placed','Placed'],
               f'Confusion Matrix – Placement ({best_pl_name})',
               '09_placement_confusion_matrix.png')

# Feature importance for placement
ohe_feats_p = best_pl['pipe'].named_steps['pre'].named_transformers_['cat']\
              .get_feature_names_out(cat_pl).tolist()
all_feat_names_p = num_pl + ohe_feats_p
plot_feature_importance(best_pl['pipe'].named_steps['model'], all_feat_names_p,
                        f'Feature Importance – Placement ({best_pl_name})',
                        '10_placement_feature_importance.png')

# AUC comparison
plt.figure(figsize=(7, 5))
names_p = list(pl_results.keys())
aucs    = [pl_results[n]['test_auc'] for n in names_p]
plt.bar(names_p, aucs, color=['steelblue','coral'])
plt.xticks(rotation=10, ha='right')
plt.ylabel('ROC-AUC'); plt.ylim(0, 1)
plt.title('Placement Model Comparison – ROC-AUC')
plt.tight_layout()
plt.savefig(os.path.join(OUT_DIR, '11_placement_model_comparison.png'), dpi=150)
plt.close()
print("Saved: 11_placement_model_comparison.png")

# =============================================================================
# FINAL SUMMARY TABLE
# =============================================================================
sep("FINAL SUMMARY OF ALL MODEL RESULTS")

summary_df = pd.DataFrame(results_summary)
print(summary_df.to_string(index=False))
summary_df.to_csv(os.path.join(OUT_DIR, 'model_results_summary.csv'), index=False)
print(f"\nSaved: model_results_summary.csv")

sep("PREDICTIVE ANALYSIS COMPLETE")
print(f"All outputs written to: {OUT_DIR}")
print("Files generated:")
for f in sorted(os.listdir(OUT_DIR)):
    print(f"  → {f}")
