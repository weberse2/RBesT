gmap_binomial_fixed_tau_compact_spec <- 
list(name = "gmap_binomial_fixed_tau", seed = 873461L, nc = 1L, 
    has_intercept = TRUE, tau_fixed = TRUE, tau_values = c(`tau[1]` = 0.5), 
    variables_model = c("beta[1]", "lp__"), variables_theta = c("theta[1]", 
    "theta[2]", "theta[3]", "theta[4]", "theta[5]", "theta[6]", 
    "theta[7]", "theta[8]", "theta_resp_pred"), variables = c("theta[1]", 
    "theta[2]", "theta[3]", "theta[4]", "theta[5]", "theta[6]", 
    "theta[7]", "theta[8]", "beta[1]", "tau[1]", "theta_pred", 
    "theta_resp_pred", "lp__"), draws_dim = c(100L, 2L, 13L), 
    diag_variables = c("accept_stat__", "stepsize__", "treedepth__", 
    "n_leapfrog__", "divergent__", "energy__"), metadata_mcmc = list(
        iter = 200, warmup = 100, warmup_saved = 0L, chains = 2, 
        n_save_per_chain = 100, post_warmup_saved = 100, thin_input = 1, 
        thin_post = 1L, save_warmup = FALSE), mvn_model = structure(c(1, 
    -1.10836319390812, -286.659302684881, 0.185674748742882, 
    2.25184735445771, -0.0675042595217763), dim = c(6L, 1L), dimnames = list(
        c("w", "m[beta[1]]", "m[lp__]", "s[beta[1]]", "s[lp__]", 
        "rho[lp__,beta[1]]"), "comp1"), link = structure(list(
        name = "identity", link = function (x) 
        x, invlink = function (x) 
        x, Jinv_orig = function (...) 
        do.call(FUN, c(.orig, list(...))), lJinv_orig = function (...) 
        do.call(FUN, c(.orig, list(...))), lJinv_link = function (...) 
        do.call(FUN, c(.orig, list(...)))), class = "dlink"), class = c("mvnormMix", 
    "mix"), likelihood = "mvnormal"), mvn_theta = structure(c(1, 
    -1.27548969657249, -1.01022029799902, -0.667408837251961, 
    -1.1956949364136, -0.987104458112686, -0.93655006676329, 
    -1.75011683361638, -0.982689135458149, 0.249332138814971, 
    0.207072639416784, 0.323479685056586, 0.248698178560331, 
    0.320548177202941, 0.172119787778131, 0.315751353908039, 
    0.276706292679105, 0.300090341938198, 0.0934128591093406, 
    -0.0260766679569007, 0.147925171618529, 0.0891540800730423, 
    -0.0178324856630775, -0.00996789160187421, 0.0330004805215178, 
    0.0830401181881987, 0.0553495157358973, -0.029162230377652, 
    0.205925413763043, -0.0660857913947855, 0.178415756334161, 
    -0.0266988386867489, 0.005585407486958, 0.0790567464667486, 
    -0.000797928351173124, 0.0513224843547366, -0.152154669834383, 
    0.23758982014389, 0.143714693291563, 0.101830332939969, -0.0851935973600432, 
    0.176892142888938, -0.078962720194654, 0.153625250511528, 
    0.0790629112505944, -0.026039445391934, -0.0499274109870239, 
    -0.0255843110239608, -0.0159596946024283, 0.0429857707424812, 
    -0.0557368938549019, 0.0297033385882292, 0.119333119673389, 
    0.0753541681527655, 0.120683285623557), dim = c(55L, 1L), dimnames = list(
        c("w", "m[theta[1]]", "m[theta[2]]", "m[theta[3]]", "m[theta[4]]", 
        "m[theta[5]]", "m[theta[6]]", "m[theta[7]]", "m[theta[8]]", 
        "m[theta_resp_pred]", "s[theta[1]]", "s[theta[2]]", "s[theta[3]]", 
        "s[theta[4]]", "s[theta[5]]", "s[theta[6]]", "s[theta[7]]", 
        "s[theta[8]]", "s[theta_resp_pred]", "rho[theta[2],theta[1]]", 
        "rho[theta[3],theta[1]]", "rho[theta[4],theta[1]]", "rho[theta[5],theta[1]]", 
        "rho[theta[6],theta[1]]", "rho[theta[7],theta[1]]", "rho[theta[8],theta[1]]", 
        "rho[theta_resp_pred,theta[1]]", "rho[theta[3],theta[2]]", 
        "rho[theta[4],theta[2]]", "rho[theta[5],theta[2]]", "rho[theta[6],theta[2]]", 
        "rho[theta[7],theta[2]]", "rho[theta[8],theta[2]]", "rho[theta_resp_pred,theta[2]]", 
        "rho[theta[4],theta[3]]", "rho[theta[5],theta[3]]", "rho[theta[6],theta[3]]", 
        "rho[theta[7],theta[3]]", "rho[theta[8],theta[3]]", "rho[theta_resp_pred,theta[3]]", 
        "rho[theta[5],theta[4]]", "rho[theta[6],theta[4]]", "rho[theta[7],theta[4]]", 
        "rho[theta[8],theta[4]]", "rho[theta_resp_pred,theta[4]]", 
        "rho[theta[6],theta[5]]", "rho[theta[7],theta[5]]", "rho[theta[8],theta[5]]", 
        "rho[theta_resp_pred,theta[5]]", "rho[theta[7],theta[6]]", 
        "rho[theta[8],theta[6]]", "rho[theta_resp_pred,theta[6]]", 
        "rho[theta[8],theta[7]]", "rho[theta_resp_pred,theta[7]]", 
        "rho[theta_resp_pred,theta[8]]"), "comp1"), link = structure(list(
        name = "identity", link = function (x) 
        x, invlink = function (x) 
        x, Jinv_orig = function (...) 
        do.call(FUN, c(.orig, list(...))), lJinv_orig = function (...) 
        do.call(FUN, c(.orig, list(...))), lJinv_link = function (...) 
        do.call(FUN, c(.orig, list(...)))), class = "dlink"), class = c("mvnormMix", 
    "mix"), likelihood = "mvnormal"), builder = function () 
    {
        withr::with_options(list(RBesT.MC.save_warmup = FALSE), 
            gMAP(cbind(r, n - r) ~ 1 | study, family = binomial, 
                data = AS, tau.dist = "Fixed", tau.prior = 0.5, 
                beta.prior = 2, warmup = 100, iter = 200, chains = 0, 
                thin = 1))
    })
