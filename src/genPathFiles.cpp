/**
# CDKAM: a metagenomic classification tool using discriminative k-mers and approximate matching strategy
# Copyright 2019-2020
# Department of Bioinformatics and Biostatistics, Shanghai Jiao Tong University
# Contact information: buikien.dp@sjtu.edu.cn, ccwei@sjtu.edu.cn
#
# Function: Generating each species's genome from .fna file
*/
//  g++ -std=c++11 -o genPathFiles genPathFiles.cpp -O3
#include "helpers.h"

#define maxn 3000005   // ???? 3000005

string mapSpecies[maxn], mapGenus[maxn], mapFamily[maxn], mapOrder[maxn], mapClass[maxn], mapPhylum[maxn];
IIS parent[maxn];


vector<string> tokenize(const string& row) {
    vector<string> tokens;
    if (row.empty()) return tokens;
    for (int i=0, pos=0, n=row.size(); i < n; ++i) {
        if (i==n-1 || row[i+1]=='|' || row[i+1] == ' ') {
            int len = (i+1)-pos;
            if (len < 0) len = 0;
            string token = row.substr(pos, len);
            tokens.push_back(token);
            pos = i+2;
        }
    }
    return tokens;
}


string toString(int n) {
    if (n == -1) return "-1";
    string ans = "";
    while (n) {
        ans = char(n%10 + 48) + ans;
        n /= 10;
    }
    return ans;
}

void usage() {
    cerr << "./genSpecies premap.txt nodes.dmp library.fna $library_name.txt\n";
}


int main (int argc, char **argv) {
    if (argc != 5) {
        usage();
        exit(1);
    }
    ifstream fin(argv[1]);
    ifstream fin2(argv[2]);
    ifstream fin3(argv[3]);


    /// Read Taxonomy NCBI file (nodes.dmp)
    for (size_t i = 1; i < maxn; ++i) {
        parent[i] = IIS("", 0);
    }

    string t;
    while (getline(fin2, t)) {
        if (t.empty()) continue;

        // ????????? ?????? ?? "\t|\t"
        vector<string> V;
        size_t start = 0, pos;
        while ((pos = t.find("\t|\t", start)) != string::npos) {
            V.push_back(t.substr(start, pos - start));
            start = pos + 3;
        }
        // ????????? ????? (???? ????? ???? ?????? ? \t| ? ?????)
        size_t end = t.find("\t|", start);
        if (end != string::npos) {
            V.push_back(t.substr(start, end - start));
        } else {
            V.push_back(t.substr(start));
        }

        if (V.size() < 3) continue; // ?????? ???? ???? ?? tax_id, parent_id, rank

        int u = toNum(V[0]); // tax_id
        int v = toNum(V[1]); // parent_tax_id
        string rank = V[2];

        if (u <= 0 || u >= (int)maxn) continue;
        parent[u] = IIS(rank, v);
    }


    /// Read Premap.txt
    string taxid;
    while (fin >> taxid) {
        if (taxid.empty()) continue;
        vector<string> V = tokenize(taxid); // ???????: CDKAM|GCF_xxx|<taxid>|NC_xxx
        if (V.size() < 3) continue;         // ???????????? ???????

        int strainID = toNum(V[2]);
        if (strainID <= 0 || strainID >= (int)maxn) continue; // ??????

        int phylumID = -1, classID = -1, orderID = -1, familyID = -1, genusID = -1, speciesID = strainID;
        int st = strainID;
        while (st != 131567) {
            if (st <= 2 || st >= (int)maxn) break;
            if (parent[st].first == "species")      speciesID = st;
            else if (parent[st].first == "genus")   genusID = st;
            else if (parent[st].first == "family")  familyID = st;
            else if (parent[st].first == "order")   orderID = st;
            else if (parent[st].first == "class")   classID = st;
            else if (parent[st].first == "phylum")  phylumID = st;
            st = parent[st].second;
        }

        mapSpecies[strainID] = toString(speciesID);
        mapGenus[strainID]   = toString(genusID);
        mapFamily[strainID]  = toString(familyID);
        mapOrder[strainID]   = toString(orderID);
        mapClass[strainID]   = toString(classID);
        mapPhylum[strainID]  = toString(phylumID);
    }

    fin.close();


    /// Read library.fna and then split it into TaxaID files
    // ????????, ??? ??????? ??????????
    {
        std::string outdir = std::string(argv[4]) + "/references";
        std::string cmd = "mkdir -p \"" + outdir + "\"";
        int ret = system(cmd.c_str());
        if (ret != 0) {
            std::cerr << "[ERROR] Failed to execute: " << cmd << std::endl;
        }
    }

    string s, oldFile = "";
    vector<string> Genome;
    vector<IIS> Vlink;

    while (getline(fin3, s)) {
        if (s.empty()) continue;             // ??????
        if (s[0] == '>') {
            if (!oldFile.empty()) {
                vector<string> V = tokenize(oldFile);
                if (V.size() >= 4) {
                    string file = "references/" + V[1] + "|" + V[2] + "|" + V[3] + ".txt";
                    int id = toNum(V[2]);
                    if (id > 0 && id < (int)maxn) {
                        string link = string(argv[4]); link += "/" + file;
                        ofstream ofs(link.c_str(), std::ios_base::app);
                        ofs << oldFile << "\n";
                        for (auto &i : Genome) ofs << i << "\n";
                        ofs.close();
                        Genome.clear(); Genome.shrink_to_fit();
                        Vlink.push_back(IIS(link, id));
                    }
                }
            }
            oldFile = s;
        } else {
            Genome.push_back(s);
        }
    }

    // ????????? ?????
    if (!oldFile.empty()) {
        vector<string> V = tokenize(oldFile);
        if (V.size() >= 4) {
            string file = "references/" + V[1] + "|" + V[2] + "|" + V[3] + ".txt";
            int id = toNum(V[2]);
            if (id > 0 && id < (int)maxn) {
                string link = string(argv[4]); link += "/" + file;
                ofstream ofs(link.c_str(), std::ios_base::app);
                ofs << oldFile << "\n";
                for (auto &i : Genome) ofs << i << "\n";
                ofs.close();
                Genome.clear(); Genome.shrink_to_fit();
                Vlink.push_back(IIS(link, id));
            }
        }
    }
    fin3.close();



    /// Print library_name.txt, consists of file link and the full taxonomy path
    string output(argv[4]);
    output += "/build/paths.txt";
    ofstream fout(output.c_str());
    sort(Vlink.begin(), Vlink.end());
    Vlink.erase(unique(Vlink.begin(), Vlink.end()), Vlink.end());
    for (auto i : Vlink) {
        int id = i.second;
        i.first += "\t" + toString(id) + "\t" + mapSpecies[id] + "\t" + mapGenus[id] + "\t" + mapFamily[id] + "\t" + mapOrder[id] + "\t" + mapClass[id] + "\t" + mapPhylum[id];
        fout << i.first << "\n";
    }
    fout.close();

    return 0;
}
