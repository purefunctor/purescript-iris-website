
use std::{env, fs, path::Path};

fn main() {
    let manifest_dir = env::var("CARGO_MANIFEST_DIR").unwrap();
    let lock = Path::new(&manifest_dir).join("Cargo.lock");
    println!("cargo:rerun-if-changed={}", lock.display());
    let lock = fs::read_to_string(&lock).unwrap_or_default();
    let source = lock
        .split("[[package]]")
        .find(|package| package.contains("\nname = \"building\"\n"))
        .and_then(|package| package.lines().find_map(|line| line.strip_prefix("source = \"")))
        .and_then(|source| source.strip_suffix('"'))
        .and_then(|source| source.split_once("?tag="))
        .map(|(_, tag)| match tag.split_once('#') {
            Some((tag, commit)) => format!("{tag} ({})", &commit[..commit.len().min(12)]),
            None => tag.to_string(),
        });
    println!("cargo:rustc-env=IRIS_SOURCE={}", source.as_deref().unwrap_or("unknown"));
}
