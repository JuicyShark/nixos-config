{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  pname = "1filellm";
  version = "latest";

  src = pkgs.fetchFromGitHub {
    owner = "jimmc414";
    repo = "1filellm";
    rev = "23b90970979bc5bab82315613fc051938ffdb6d0";
    sha256 = "sha256-g3od+PvCqTe4RoyCnU1D/tAuqZmnVeBnsG1tjda75Fo=";
  };

  nativeBuildInputs = [ pkgs.python3 pkgs.makeWrapper ];
  propagatedBuildInputs = with pkgs.python312Packages; [ requests beautifulsoup4 pypdf2 tiktoken nltk nbformat nbformat youtube-transcript-api pyperclip wget tqdm rich ];

  buildPhase = ''
    mkdir -p $out/bin
    cp onefilellm.py $out/bin/1filellm.py
    chmod +x $out/bin/1filellm.py
  '';

  meta = with pkgs.lib; {
    description = "1FileLLM: A lightweight Python-based LLM summarization tool.";
    homepage = "https://github.com/jimmc414/1filellm";
    license = licenses.mit;
    maintainers = with maintainers; [ yourname ];
  };
}

