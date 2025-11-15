lgb_grid <-
  list(
    objective = "binary",
    metric = "binary_logloss",
    min_sum_hessian_in_leaf = 0.2,
    feature_fraction = 0.7,
    bagging_fraction = 0.7,
    bagging_freq = 20,
    min_data = 100,
    max_bin = 50,
    lambda_l1 = 8,
    lambda_l2 = 1.3,
    min_data_in_bin = 100,
    min_gain_to_split = 10,
    min_data_in_leaf = 30,
    is_unbalance = TRUE,
    learning_rate = 0.02,
    num_leaves = 25,
    seed = 110694
  )

lgb_grid_study <-
  list(
    boosting_type = "gbdt",
    colsample_bytree = 0.278887567783888,
    importance_type = "split",
    learning_rate = 0.055,
    max_depth = 43,
    min_child_samples = 20,
    min_child_weight = 0.0,
    min_split_gain = 0.0,
    n_estimators = 970,
    n_jobs = -1,
    num_leaves = 90,
    objective = "binary",
    reg_alpha = 1.5919775186620423e-07,
    reg_lambda = 3.048922014839336e-07,
    silent = 1,
    subsample = 0.6000000000000001,
    subsample_for_bin = 200000,
    subsample_freq = 0,
    max_delta_step = 2.0,
    seed = 110694
  )