<?php

namespace App\Filament\Resources\Products\Schemas;

use App\Models\Category;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Schema;

class ProductForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('nama')
                    ->label('Nama Produk')
                    ->required()
                    ->maxLength(255),
                Select::make('kategori')
                    ->label('Kategori')
                    ->required()
                    ->options(function () {
                        return Category::pluck('nama_kategori', 'nama_kategori')->toArray();
                    })
                    ->searchable()
                    ->createOptionUsing(function (string $value): string {
                        Category::firstOrCreate(['nama_kategori' => $value]);
                        return $value;
                    }),
                TextInput::make('harga')
                    ->label('Harga')
                    ->required()
                    ->numeric()
                    ->prefix('Rp')
                    ->minValue(0),
                TextInput::make('stok')
                    ->label('Stok')
                    ->required()
                    ->numeric()
                    ->minValue(0)
                    ->default(0),
                TextInput::make('satuan_jual')
                    ->label('Satuan Jual')
                    ->placeholder('Contoh: ikat, kg, liter, pak')
                    ->required()
                    ->maxLength(50),
                Toggle::make('tersedia')
                    ->label('Tersedia untuk Dijual')
                    ->default(true),
                Toggle::make('mudah_rusak')
                    ->label('Mudah Rusak (Wajib Same-Day)')
                    ->helperText('Jika aktif, pemesanan hanya diizinkan untuk pengantaran pada hari yang sama.')
                    ->default(false),
                Textarea::make('deskripsi')
                    ->label('Deskripsi Produk')
                    ->nullable()
                    ->columnSpanFull(),
            ]);
    }
}
